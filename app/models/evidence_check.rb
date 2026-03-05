class EvidenceCheck < ApplicationRecord
  belongs_to :evidence_agent_credential
  belongs_to :organization
  belongs_to :compliance_control, optional: true

  enum status: { enabled: 0, disabled: 1 }, _prefix: true
  enum last_result: { pass: 0, fail: 1, error_result: 2 }, _prefix: true

  validates :check_type, presence: true

  scope :active, -> { where(status: :enabled) }
  scope :overdue, -> { where('last_run_at < ?', 24.hours.ago).or(where(last_run_at: nil)) }
  scope :failing, -> { where(last_result: :fail) }

  def provider
    evidence_agent_credential.provider
  end

  def provider_info
    evidence_agent_credential.provider_info
  end

  def stale?
    last_run_at.nil? || last_run_at < schedule_interval.ago
  end

  private

  def schedule_interval
    case schedule
    when 'daily' then 1.day
    when 'weekly' then 1.week
    when 'monthly' then 1.month
    else 1.day
    end
  end
end
