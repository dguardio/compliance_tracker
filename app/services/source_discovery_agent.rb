class SourceDiscoveryAgent
  def call(sector:, jurisdiction:)
    Rails.logger.info "SourceDiscoveryAgent called with sector: #{sector}, jurisdiction: #{jurisdiction}"

    prompt = <<~PROMPT
      Find the key regulatory bodies and their primary websites for the "#{sector}" sector in "#{jurisdiction}".
      For each identified body, provide the name, the full URL, and classify the source type as 'web_scrape', 'rss', or 'api'.
      If you cannot determine the type, default to 'web_scrape'.
      Return the data as a JSON array of objects, where each object has the keys "name", "url", and "source_type".
      Ensure the output is only the JSON array, with no other text or explanation.
    PROMPT

    response = RubyLLM.chat.ask(prompt)
    Rails.logger.info "SourceDiscoveryAgent Raw LLM Response: #{response.content}"
    parse_response(response.content)
  end

  private

  def parse_response(response_content)
    begin
      # The response might contain markdown, so we need to extract the JSON part.
      json_match = response_content.match(/```json\n(.*)\n```/m)
      if json_match
        JSON.parse(json_match[1])
      else
        JSON.parse(response_content)
      end
    rescue JSON::ParserError
      # Handle cases where the LLM doesn't return valid JSON.
      # For now, we'll just return an empty array.
      Rails.logger.error "Failed to parse JSON response from LLM: #{response_content}"
      []
    end
  end
end
