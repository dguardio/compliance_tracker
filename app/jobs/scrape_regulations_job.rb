# frozen_string_literal: true

# A master job to trigger the scraping of all enrolled regulatory authorities.
# This job is intended to be run on a schedule. It does no heavy lifting itself;
# it just fans out work to `ScrapeSingleSourceJob` workers.
class ScrapeRegulationsJob < ApplicationJob
  queue_as :default

  # @param options [Hash] Optional parameters (e.g., limit: 5 for testing)
  def perform(options = {})
    Rails.logger.info "ScrapeRegulationsJob (Master) started with options: #{options}"
    
    data_sources = RegulatoryDataSource.enabled.includes(:provider)
    
    data_sources.find_each do |data_source|
      Rails.logger.info "Enqueuing ScrapeSingleSourceJob for #{data_source.name}"
      ScrapeSingleSourceJob.perform_later(data_source.id, options)
    end
    
    Rails.logger.info 'ScrapeRegulationsJob (Master) finished dispatching workers.'
  end
end

