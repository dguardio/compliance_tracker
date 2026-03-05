class ExternalTicket < ApplicationRecord
  belongs_to :external_integration
  belongs_to :organization
  belongs_to :finding, optional: true
  belongs_to :incident, optional: true

  validates :external_id, presence: true, uniqueness: { scope: :external_integration_id }

  scope :recent, -> { order(last_synced_at: :desc) }
  scope :for_findings, -> { where.not(finding_id: nil) }
  scope :for_incidents, -> { where.not(incident_id: nil) }

  def provider
    external_integration.provider
  end

  def provider_info
    external_integration.provider_info
  end

  def source_type
    return 'Finding' if finding_id.present?
    return 'Incident' if incident_id.present?
    'Unknown'
  end

  def source
    finding || incident
  end
end
