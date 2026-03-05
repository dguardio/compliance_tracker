class EvidenceAgentCredential < ApplicationRecord
  belongs_to :organization
  has_many :evidence_checks, dependent: :destroy

  enum status: { active: 0, inactive: 1, error: 2 }, _prefix: true

  validates :provider, presence: true
  validates :label, presence: true

  PROVIDERS = {
    'github' => { name: 'GitHub', icon: 'fab fa-github', color: '#333' },
    'aws' => { name: 'AWS', icon: 'fab fa-aws', color: '#FF9900' },
    'google_workspace' => { name: 'Google Workspace', icon: 'fab fa-google', color: '#4285F4' },
    'azure' => { name: 'Azure', icon: 'fab fa-microsoft', color: '#0078D4' }
  }.freeze

  def provider_info
    PROVIDERS[provider] || { name: provider.titleize, icon: 'fas fa-plug', color: '#6b7280' }
  end

  def connected?
    status_active? && last_connected_at.present?
  end
end
