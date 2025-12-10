# frozen_string_literal: true

class RegulatoryDataSource < ApplicationRecord
  belongs_to :provider

  enum source_type: { api: 'api', rss: 'rss', web_scrape: 'web_scrape', document_repository: 'document_repository' }
  enum status: { enabled: 0, disabled: 1, error: 2 }

  validates :name, presence: true, uniqueness: { scope: :provider_id }
  validates :source_type, presence: true
  validates :url, presence: true
  validates :provider, presence: true
  
  encrypts :api_key


  validate :validate_api_settings, if: :api?

  before_validation :normalize_jsonb_attributes

  def validate_api_settings
    return unless settings.present?

    required_keys = %w[results_key title_key url_key]
    missing_keys = required_keys - settings.keys
    
    if missing_keys.any?
      errors.add(:settings, "must contain the following keys for API source: #{missing_keys.join(', ')}")
    end
  end

  def auto_configure!
    Regulatory::SmartConfiguratorService.new(self).call
  end

  private

  def normalize_jsonb_attributes
    self.sectors = normalize_attribute(sectors)
    self.jurisdictions = normalize_attribute(jurisdictions)
  end

  def normalize_attribute(attr)
    return [] unless attr.present?
    return attr if attr.is_a?(Array)

    attr.split(',').map(&:strip).reject(&:blank?).uniq
  end
end
