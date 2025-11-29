namespace :regulations do
  desc "Ingest regulations from all enabled data sources"
  task ingest: :environment do
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.info "Starting manual regulation ingestion..."
    RegulatoryScraperService.new.scrape_all
    Rails.logger.info "Ingestion complete."
  end
end
