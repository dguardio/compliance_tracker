class Obligation < ApplicationRecord
  belongs_to :organization
  belongs_to :regulation, optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :obligation_controls, dependent: :destroy
  has_many :compliance_controls, through: :obligation_controls
  has_many :findings, dependent: :nullify

  # Enums
  enum status: {
    identified: 0,
    active: 1,
    in_progress: 2,
    completed: 3,
    waived: 4,
    expired: 5
  }, _prefix: true

  enum priority: {
    low: 0,
    medium: 1,
    high: 2,
    critical: 3
  }, _prefix: true

  enum frequency: {
    one_time: 0,
    recurring_monthly: 1,
    recurring_quarterly: 2,
    recurring_annually: 3,
    event_driven: 4
  }, _prefix: true

  enum obligation_type: {
    regulatory: 0,
    contractual: 1,
    internal_policy: 2,
    industry_standard: 3,
    conditional: 4
  }, _prefix: true

  # Validations
  validates :title, presence: true
  validates :status, presence: true

  # Scopes
  scope :active_obligations, -> { where(status: [:identified, :active, :in_progress]) }
  scope :overdue, -> { active_obligations.where('due_date < ?', Date.current) }
  scope :due_soon, -> { active_obligations.where('due_date BETWEEN ? AND ?', Date.current, 14.days.from_now) }
  scope :by_priority, -> { order(priority: :desc) }
  scope :conditional, -> { where(obligation_type: :conditional) }
  scope :recent, -> { order(created_at: :desc) }

  def overdue?
    due_date.present? && due_date < Date.current && !status_completed? && !status_waived? && !status_expired?
  end

  def due_soon?
    due_date.present? && due_date <= 14.days.from_now.to_date && !overdue?
  end

  # Trigger conditional obligations when an incident matches
  def self.trigger_for_incident(incident)
    return unless incident.organization.present?

    conditional.where(organization: incident.organization).find_each do |obligation|
      next if obligation.status_completed? || obligation.status_waived?

      obligation.update!(
        status: :in_progress,
        due_date: obligation.calculate_conditional_deadline(incident)
      )
    end
  end

  def calculate_conditional_deadline(incident)
    # GDPR 72h breach notification, etc.
    case regulation&.name
    when /GDPR/i
      incident.detected_at.present? ? (incident.detected_at + 72.hours).to_date : 3.days.from_now.to_date
    else
      due_date || 30.days.from_now.to_date
    end
  end
end
