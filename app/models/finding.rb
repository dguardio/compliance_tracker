class Finding < ApplicationRecord
  belongs_to :organization
  belongs_to :compliance_control, optional: true
  belongs_to :compliance_requirement, optional: true
  belongs_to :compliance_framework, optional: true
  belongs_to :document, optional: true
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :corrective_actions, dependent: :destroy

  # Enums
  enum source: {
    manual: 0,
    control_effectiveness: 1,
    evidence_expiration: 2,
    audit: 3,
    risk_assessment: 4
  }, _prefix: true

  enum severity: {
    low: 0,
    medium: 1,
    high: 2,
    critical: 3
  }, _prefix: true

  enum status: {
    open: 0,
    in_progress: 1,
    remediated: 2,
    closed: 3,
    accepted: 4
  }, _prefix: true

  enum root_cause: {
    not_determined: 0,
    process_gap: 1,
    training_gap: 2,
    technology_failure: 3,
    human_error: 4,
    policy_gap: 5,
    third_party: 6,
    resource_constraint: 7,
    other: 8
  }, _prefix: true

  # Validations
  validates :title, presence: true
  validates :source, presence: true
  validates :severity, presence: true
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: [:open, :in_progress]) }
  scope :overdue, -> { active.where('sla_deadline < ?', Time.current) }
  scope :by_severity, ->(sev) { where(severity: sev) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_create :set_sla_deadline

  def overdue?
    sla_deadline.present? && sla_deadline < Time.current && active?
  end

  def active?
    status_open? || status_in_progress?
  end

  def resolve!(notes = nil)
    update!(
      status: :closed,
      resolved_at: Time.current,
      resolution_notes: notes
    )
  end

  private

  def set_sla_deadline
    return if sla_deadline.present?

    days = case severity
           when 'critical' then 3
           when 'high' then 7
           when 'medium' then 14
           when 'low' then 30
           else 30
           end

    self.sla_deadline = Time.current + days.days
  end
end
