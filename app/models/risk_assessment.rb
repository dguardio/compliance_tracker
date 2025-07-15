class RiskAssessment < ApplicationRecord
  belongs_to :organization
  belongs_to :compliance_framework
  belongs_to :compliance_requirement
  belongs_to :compliance_control
  belongs_to :created_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'User'

  # Enums
  enum likelihood: {
    very_low: 1,
    low: 2,
    medium: 3,
    high: 4,
    very_high: 5
  }

  enum impact: {
    negligible: 1,
    minor: 2,
    moderate: 3,
    major: 4,
    catastrophic: 5
  }

  enum status: {
    draft: 0,
    in_progress: 1,
    completed: 2,
    reviewed: 3,
    approved: 4,
    archived: 5
  }

  # Validations
  validates :name, presence: true
  validates :likelihood, presence: true, inclusion: { in: likelihoods.keys }
  validates :impact, presence: true, inclusion: { in: impacts.keys }
  validates :status, presence: true, inclusion: { in: statuses.keys }
  validates :assessment_date, presence: true
  validates :next_review_date, presence: true
  validate :next_review_date_after_assessment_date

  # Scopes
  scope :active, -> { where.not(status: :archived) }
  scope :overdue, -> { where('next_review_date < ?', Date.current) }
  scope :due_soon, -> { where('next_review_date BETWEEN ? AND ?', Date.current, 30.days.from_now) }
  scope :high_risk, -> { where('risk_score >= ?', 15) }
  scope :by_organization, ->(org) { where(organization: org) }

  # Callbacks
  before_save :calculate_risk_score
  after_save :check_overdue_notification

  # Instance methods
  def risk_level
    case risk_score
    when 1..4
      'Very Low'
    when 5..8
      'Low'
    when 9..12
      'Medium'
    when 13..16
      'High'
    when 17..25
      'Very High'
    else
      'Unknown'
    end
  end

  def risk_level_color
    case risk_score
    when 1..4
      'green'
    when 5..8
      'blue'
    when 9..12
      'yellow'
    when 13..16
      'orange'
    when 17..25
      'red'
    else
      'gray'
    end
  end

  def overdue?
    next_review_date < Date.current
  end

  def due_soon?
    next_review_date.between?(Date.current, 30.days.from_now)
  end

  def days_until_review
    (next_review_date - Date.current).to_i
  end

  private

  def calculate_risk_score
    self.risk_score = likelihood_value * impact_value
  end

  def likelihood_value
    RiskAssessment.likelihoods[likelihood] || 1
  end

  def impact_value
    RiskAssessment.impacts[impact] || 1
  end

  def next_review_date_after_assessment_date
    return unless next_review_date && assessment_date

    return unless next_review_date < assessment_date

    errors.add(:next_review_date, 'must be after assessment date')
  end

  def check_overdue_notification
    # Send overdue notification if the assessment just became overdue
    return unless saved_change_to_next_review_date? && overdue? && !overdue_notification_sent?

    send_overdue_notification
  end

  def send_overdue_notification
    RiskAssessmentNotificationNotifier.with(
      risk_assessment: self,
      action: :overdue,
      actor: created_by
    ).deliver_later(assigned_to)

    # Also notify organization admins
    organization.users.joins(:roles).where(roles: { name: %w[org_admin super_admin] }).each do |admin|
      next if admin == assigned_to

      RiskAssessmentNotificationNotifier.with(
        risk_assessment: self,
        action: :overdue,
        actor: created_by
      ).deliver_later(admin)
    end

    # Mark as notified (you might want to add a field for this)
    # self.update_column(:overdue_notification_sent, true)
  end

  def overdue_notification_sent?
    # For now, we'll always send the notification
    # You could add a field to track this
    false
  end
end
