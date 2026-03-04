require "test_helper"

class Api::V1::IngestionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @provider = Provider.first || Provider.create!(
      name: "Test Provider",
      jurisdiction: "US",
      country: "United States"
    )
    @data_source = RegulatoryDataSource.create!(
      name: "Test Source",
      provider: @provider,
      source_type: "web_scrape",
      url: "https://example.com",
      settings: { "scraping_engine" => "external_scrapling" }
    )
  end

  test "should create regulation and enqueue job on valid webhook" do
    initial_count = Regulation.count
    post '/api/v1/ingestions/webhook', params: {
      data_source_id: @data_source.id,
      url: "https://example.com/doc.pdf",
      title: "Test Regulation",
      publication_date: "2023-01-01",
      content: "Extracted regulation text"
    }, as: :json
    
    assert_equal initial_count + 1, Regulation.count
    
    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    
    regulation = Regulation.last
    assert_equal "Test Regulation", regulation.title
    assert_equal "Extracted regulation text", regulation.main_text
  end
end
