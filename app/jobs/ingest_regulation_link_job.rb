# frozen_string_literal: true

# Job to download, extract text, and ingest a single regulation from a URL.
# This enables massive concurrency: 100 links found on a page = 100 separate jobs.
class IngestRegulationLinkJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(url, data_source_id, encoded_raw_data = {})
    data_source = RegulatoryDataSource.find_by(id: data_source_id)
    unless data_source
      Rails.logger.warn "IngestRegulationLinkJob: Missing RegulatoryDataSource ID #{data_source_id}"
      return
    end

    Rails.logger.info "IngestRegulationLinkJob starting for: #{url}"
    
    # We parse the primitive hash back, which might contain title or publication_date
    # that was extracted during the list-view scrape.
    raw_data = encoded_raw_data.symbolize_keys

    scraper = RegulatoryScraperService.new
    scraper.process_regulation_link(url, data_source, raw_data[:title], raw_data[:publication_date], raw_data[:api_payload])
  end
end
