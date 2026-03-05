# frozen_string_literal: true

# Job to scrape a single regulatory data source.
# It delegates the actual parsing logic to the RegulatoryScraperService,
# which has been updated to enqueue IngestRegulationLinkJob for each found document.
class ScrapeSingleSourceJob < ApplicationJob
  queue_as :default

  def perform(data_source_id, options = {})
    data_source = RegulatoryDataSource.find_by(id: data_source_id)
    unless data_source
      Rails.logger.warn "ScrapeSingleSourceJob could not find RegulatoryDataSource with ID #{data_source_id}"
      return
    end

    Rails.logger.info "ScrapeSingleSourceJob started for: #{data_source.name} (Type: #{data_source.source_type})"
    
    # Delegate to the service, passing any limits for testing
    scraper = RegulatoryScraperService.new
    scraper.scrape_data_source(data_source, options.symbolize_keys)

    # Note: last_synced_at is updated inside the service after successful extraction.
    
    Rails.logger.info "ScrapeSingleSourceJob finished for: #{data_source.name}"
  end
end
