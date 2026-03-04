require "test_helper"

class RegulatoryDataSourceTest < ActiveSupport::TestCase
  def setup
    @provider = Provider.first || Provider.create!(
      name: "Test Provider",
      jurisdiction: "US",
      country: "United States"
    )
  end

  test "external_scraper? returns true when scraping_engine is external_scrapling" do
    data_source = RegulatoryDataSource.new(
      name: "Test Source 1",
      provider: @provider,
      source_type: "web_scrape",
      url: "https://example.com",
      settings: { "scraping_engine" => "external_scrapling" }
    )
    assert data_source.external_scraper?
  end

  test "external_scraper? returns false when scraping_engine is not set" do
    data_source = RegulatoryDataSource.new(
      name: "Test Source 2",
      provider: @provider,
      source_type: "web_scrape",
      url: "https://example.com",
      settings: {}
    )
    assert_not data_source.external_scraper?
  end
end
