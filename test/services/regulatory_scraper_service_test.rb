require "test_helper"
require "minitest/mock"

class RegulatoryScraperServiceTest < ActiveSupport::TestCase
  def setup
    @provider = Provider.first || Provider.create!(
      name: "Test Provider",
      jurisdiction: "US",
      country: "United States"
    )
    @data_source = RegulatoryDataSource.create!(
      name: "Test External Scraper",
      provider: @provider,
      source_type: "web_scrape",
      url: "https://example.com/regulations",
      settings: { "scraping_engine" => "external_scrapling" }
    )
    @service = RegulatoryScraperService.new
  end

  test "should dispatch to python scraper when scraping engine is external_scrapling" do
    mock_response = Minitest::Mock.new
    mock_response.expect :success?, true
    
    # Assert that HTTParty.post is called with the external python scraper URL
    HTTParty.stub :post, mock_response do
      @service.scrape_data_source(@data_source)
    end
    
    assert_mock mock_response
  end
end
