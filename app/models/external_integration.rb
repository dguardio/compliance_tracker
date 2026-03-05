class ExternalIntegration < ApplicationRecord
  belongs_to :organization
  has_many :external_tickets, dependent: :destroy

  enum status: { active: 0, inactive: 1, error: 2 }, _prefix: true

  validates :provider, presence: true
  validates :label, presence: true

  PROVIDERS = {
    'jira' => { name: 'Jira', icon: 'fab fa-jira', color: '#0052CC' },
    'linear' => { name: 'Linear', icon: 'fas fa-bolt', color: '#5E6AD2' },
    'servicenow' => { name: 'ServiceNow', icon: 'fas fa-cloud', color: '#81B5A1' }
  }.freeze

  def provider_info
    PROVIDERS[provider] || { name: provider.titleize, icon: 'fas fa-plug', color: '#6b7280' }
  end

  def connected?
    status_active? && last_synced_at.present?
  end

  def base_url
    config&.dig('base_url')
  end

  def project_key
    config&.dig('project_key')
  end
end
