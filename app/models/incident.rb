class Incident < ApplicationRecord
  belongs_to :organization
  belongs_to :reported_by, class_name: 'User', optional: true
  belongs_to :assigned_to, class_name: 'User', optional: true

  has_many :lesson_learneds, dependent: :destroy
  has_many :findings, dependent: :nullify

  # Enums
  enum category: {
    data_breach: 0,
    system_failure: 1,
    unauthorized_access: 2,
    policy_violation: 3,
    physical_security: 4,
    vendor_incident: 5,
    compliance_violation: 6,
    operational_disruption: 7,
    other: 8
  }, _prefix: true

  enum severity: {
    low: 0,
    medium: 1,
    high: 2,
    critical: 3
  }, _prefix: true

  enum status: {
    reported: 0,
    investigating: 1,
    contained: 2,
    resolved: 3,
    closed: 4
  }, _prefix: true

  # Validations
  validates :title, presence: true
  validates :category, presence: true
  validates :severity, presence: true
  validates :status, presence: true

  # Scopes
  scope :active_incidents, -> { where.not(status: [:resolved, :closed]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_severity, -> { order(severity: :desc) }

  # Callbacks
  after_create :auto_create_finding
  after_create :trigger_conditional_obligations

  def active?
    !status_resolved? && !status_closed?
  end

  def resolve!(resolution_notes = nil)
    update!(
      status: :resolved,
      resolved_at: Time.current,
      root_cause: resolution_notes || root_cause
    )
  end

  def close!
    update!(status: :closed)
  end

  def duration
    return nil unless occurred_at
    end_time = resolved_at || Time.current
    ((end_time - occurred_at) / 1.hour).round(1)
  end

  private

  def auto_create_finding
    return unless organization.present?
    return unless Flipper.enabled?(:findings_remediation, organization)

    Finding.create!(
      organization: organization,
      title: "Incident: #{title}",
      description: "Finding auto-created from incident: #{description}",
      source: :audit, # closest match for incident-sourced
      severity: severity, # mirror incident severity
      status: :open
    )
  rescue StandardError => e
    Rails.logger.error "Auto-create finding from incident #{id} failed: #{e.message}"
  end

  def trigger_conditional_obligations
    Obligation.trigger_for_incident(self)
  rescue StandardError => e
    Rails.logger.error "Trigger obligations for incident #{id} failed: #{e.message}"
  end
end
