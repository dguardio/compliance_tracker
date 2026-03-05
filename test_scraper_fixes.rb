require_relative 'config/environment'

# Test OCC
occ_source = RegulatoryDataSource.find_by(name: 'OCC Bulletins Web Scraper')
if occ_source
  occ_source.update(status: 'enabled')
  puts "=== Testing OCC ==="
  begin
    RegulatoryScraperService.new.scrape_data_source(occ_source, limit: 1)
    puts "OCC Jobs enqueued: #{Delayed::Job.where('handler LIKE ?', '%OCC%').count}" if defined?(Delayed::Job)
    puts "OCC status after: #{occ_source.reload.status}"
  rescue => e
    puts "OCC Exception: #{e.message}"
  end
end

# Test SEC API for UniqueViolation
sec_source = RegulatoryDataSource.find_by(name: 'SEC Federal Register API')
if sec_source
  sec_source.update(status: 'enabled')
  puts "\n=== Testing SEC API (Re-run) ==="
  begin
    RegulatoryScraperService.new.scrape_data_source(sec_source, limit: 1)
    puts "SEC API status after: #{sec_source.reload.status}"
  rescue => e
    puts "SEC API Exception: #{e.message}"
  end
end
