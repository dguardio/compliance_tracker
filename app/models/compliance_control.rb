class ComplianceControl < ApplicationRecord
  acts_as_tenant(:organization)
  resourcify
  has_paper_trail

  # Associations
  belongs_to :compliance_requirement
  belongs_to :assignee, class_name: 'User', optional: true
  has_many :risk_assessments, dependent: :destroy
  has_many :evidence_requests, dependent: :destroy
  has_many :findings, dependent: :nullify
  has_many :test_plans, dependent: :destroy
  has_many :obligation_controls, dependent: :destroy
  has_many :obligations, through: :obligation_controls
  has_many :maturity_snapshots, dependent: :destroy
  has_many :feedbacks, as: :feedbackable, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :control_type, presence: true
  validates :effectiveness, presence: true
  validates :status, presence: true
  validates :compliance_requirement, presence: true

  # Enums
  enum control_type: {
    preventive: 0,
    detective: 1,
    corrective: 2,
    deterrent: 3,
    recovery: 4
  }

  enum status: {
    draft: 'draft',
    in_progress: 'in_progress',
    implemented: 'implemented',
    needs_review: 'needs_review',
    inactive: 'inactive'
  }

  enum effectiveness: {
    low: 0,
    medium: 1,
    high: 2
  }

  enum risk_level: {
    risk_low: 0,
    risk_medium: 1,
    risk_high: 2,
    risk_critical: 3
  }

  # JSONB Settings
  jsonb_accessor :settings,
                 control_category: :string,
                 implementation_date: :date,
                 last_review_date: :date,
                 next_review_date: :date,
                 responsible_party: :string,
                 cost: :decimal,
                 frequency: :string,
                 automation_level: :string,
                 dependencies: [:string],
                 notes: :text,
                 custom_fields: :json

  # Scopes
  scope :active, -> { where.not(status: :inactive) }
  scope :effective, -> { where(effectiveness: :high) }
  scope :by_type, -> { order(:control_type) }
  scope :by_effectiveness, -> { order(:effectiveness) }
  scope :high_effectiveness, -> { where(effectiveness: :high) }
  scope :needs_review, -> { where("settings->>'next_review_date' < ?", Date.current.to_s) }
  scope :for_category, ->(category) { where("settings->>'control_category' = ?", category) }
  scope :assigned_to, ->(user) { where(assignee: user) }
  scope :unassigned, -> { where(assignee_id: nil) }
  scope :due_soon, -> { where('due_date BETWEEN ? AND ?', Date.current, 7.days.from_now) }
  scope :overdue, -> { where('due_date < ?', Date.current) }

  # Instance methods
  def display_name
    "#{name} (#{control_type.titleize})"
  end

  def effective?
    effectiveness == 'high'
  end

  def needs_review?
    return false unless settings[:next_review_date].present?

    settings[:next_review_date] < Date.current
  end

  def effectiveness_percentage
    case effectiveness
    when 'high'
      100
    when 'medium'
      66
    when 'low'
      33
    else
      0
    end
  end

  def effectiveness_color
    case effectiveness
    when 'high'
      'green'
    when 'medium'
      'yellow'
    when 'low'
      'red'
    else
      'gray'
    end
  end

  def days_until_review
    return nil unless settings[:next_review_date].present?

    (settings[:next_review_date] - Date.current).to_i
  end

  def overdue_for_review?
    days_until_review && days_until_review < 0
  end

  def implementation_age
    return nil unless settings[:implementation_date].present?

    (Date.current - settings[:implementation_date]).to_i
  end

  def cost_formatted
    return 'Not specified' unless settings[:cost].present?

    ActionController::Base.helpers.number_to_currency(settings[:cost])
  end

  def automation_level_percentage
    case settings[:automation_level]
    when 'fully_automated'
      100
    when 'semi_automated'
      75
    when 'manual_automated'
      50
    when 'mostly_manual'
      25
    when 'fully_manual'
      0
    else
      0
    end
  end

  def compliance_framework
    compliance_requirement.compliance_framework
  end

  # Auto-create Finding when effectiveness drops to low
  after_save :auto_create_finding_for_low_effectiveness, if: :saved_change_to_effectiveness?
  after_save :auto_close_findings_on_effectiveness_improvement, if: :saved_change_to_effectiveness?

  private

  def auto_create_finding_for_low_effectiveness
    return unless low?
    return unless organization.present?
    return unless Flipper.enabled?(:findings_remediation, organization)

    # Avoid duplicates
    existing = Finding.where(
      organization: organization,
      compliance_control: self,
      source: :control_effectiveness
    ).where.not(status: [:closed, :accepted])
    return if existing.exists?

    Finding.create!(
      organization: organization,
      compliance_control: self,
      compliance_requirement: compliance_requirement,
      compliance_framework: compliance_framework,
      title: "Low effectiveness detected: #{name}",
      description: "Control '#{name}' effectiveness has been set to low. Review and remediate.",
      source: :control_effectiveness,
      severity: :high,
      status: :open
    )
  rescue StandardError => e
    Rails.logger.error "Auto-create finding failed for control #{id}: #{e.message}"
  end

  def auto_close_findings_on_effectiveness_improvement
    return if low? # Only close when effectiveness improves above low
    return unless organization.present?

    Finding.where(
      organization: organization,
      compliance_control: self,
      source: :control_effectiveness,
      status: [:open, :in_progress]
    ).find_each do |finding|
      finding.resolve!("Auto-closed: control effectiveness improved to #{effectiveness}")
    end
  rescue StandardError => e
    Rails.logger.error "Auto-close finding failed for control #{id}: #{e.message}"
  end
end
