require_relative 'config/environment'

RegulatoryDataSource.enabled.each do |source|
  puts "Testing #{source.name} (Type: #{source.source_type})..."
  scraper = RegulatoryScraperService.new
  # limit to 1 document
  scraper.scrape_data_source(source, limit: 1)
end

puts "\nEnqueued Jobs:"
pp Delayed::Job.all.map(&:handler) if defined?(Delayed::Job)

