require_relative 'config/environment'

puts "Testing SEC Federal Register API Ingestion..."
source = RegulatoryDataSource.find_by(name: 'SEC Federal Register API')
if source
  puts "Found Source: #{source.name} (Type: #{source.source_type})"
  scraper = RegulatoryScraperService.new
  # limit to 1 document
  scraper.scrape_data_source(source, limit: 1)
  
  puts "Jobs enqueued:"
  pp Delayed::Job.all.map(&:handler) if defined?(Delayed::Job)
  pp ActiveJob::Base.queue_adapter.enqueued_jobs
else
  puts "Source not found!"
end
