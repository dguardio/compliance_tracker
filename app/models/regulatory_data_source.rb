# frozen_string_literal: true

class RegulatoryDataSource < ApplicationRecord
  belongs_to :provider

  enum source_type: { api: 'api', rss: 'rss', web_scrape: 'web_scrape', document_repository: 'document_repository' }
  enum status: { enabled: 0, disabled: 1, error: 2 }

  validates :name, presence: true, uniqueness: { scope: :provider_id }
  validates :source_type, presence: true
  validates :url, presence: true
  validates :provider, presence: true
end
