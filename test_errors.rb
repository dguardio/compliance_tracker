require_relative 'config/environment'

RegulatoryDataSource.where(status: 'error').update_all(status: 'enabled')

sources_to_test = RegulatoryDataSource.where(name: ['OCC Bulletins Web Scraper', 'Internal Compliance Feed'])

sources_to_test.each do |source|
  puts "Testing #{source.name} (Type: #{source.source_type})..."
  scraper = RegulatoryScraperService.new
  begin
    scraper.scrape_data_source(source, limit: 1)
  rescue => e
    puts "Error: #{e.message}"
    puts e.backtrace.first(5)
  end
end
