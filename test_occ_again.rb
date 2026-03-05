require_relative 'config/environment'

source = RegulatoryDataSource.find_by(name: 'OCC Bulletins Web Scraper')
source.update(status: 'enabled')

puts "Testing #{source.name}..."
scraper = RegulatoryScraperService.new
scraper.scrape_data_source(source, limit: 1)

puts "Status after: #{source.reload.status}"
