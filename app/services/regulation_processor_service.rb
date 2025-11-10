# frozen_string_literal: true

# Service to process raw regulation data, clean it, and extract metadata.
class RegulationProcessorService
  # Main entry point to process a regulation.
  #
  # @param regulation [Regulation] The regulation to process.
  def process(regulation)
    Rails.logger.info "Processing regulation: #{regulation.title}"
    
    # 1. Clean the raw text.
    cleaned_text = clean_raw_text(regulation.full_text)
    
    # 2. Extract metadata from the text.
    extracted_metadata = extract_metadata(cleaned_text)
    
    # 3. Update the regulation record.
    # We might add a 'processed_text' column in the future, but for now
    # we'll just update the metadata field.
    regulation.update(
      metadata: regulation.metadata.merge(extracted_metadata)
    )
    
    Rails.logger.info "Finished processing regulation: #{regulation.title}"
  end

  private

  # Cleans the raw text from the regulation.
  #
  # @param raw_text [String, Hash] The raw text, which might be JSON.
  # @return [String] The cleaned text.
  def clean_raw_text(raw_text)
    # Placeholder for text cleaning logic.
    # This could involve stripping HTML, handling different text formats, etc.
    text_content = raw_text.is_a?(Hash) ? raw_text.values.join("\n") : raw_text.to_s
    
    # Simple cleaning example:
    text_content.strip.gsub(/\s+/, ' ')
  end

  # Extracts metadata from the cleaned text using an LLM.
  # This is where the "Cube tagging" logic would go.
  #
  # @param text [String] The cleaned text.
  # @return [Hash] A hash of extracted metadata.
  def extract_metadata(text)
    return {} if text.blank?

    llm = LLM.chat

    prompt = <<~PROMPT
      You are an expert in regulatory compliance. Your task is to extract key metadata from the following regulation text.
      Provide the output in a JSON format with the following keys:
      - jurisdiction: (e.g., "Federal", "California", "EU")
      - agency: (e.g., "EPA", "FDA", "SEC")
      - effective_date: (format YYYY-MM-DD, if available)
      - summary: (a concise summary of the regulation, max 200 words)
      - keywords: (an array of 5-10 relevant keywords)
      - compliance_requirements_overview: (a brief overview of the main compliance obligations, max 150 words)
      - potential_impacted_industries: (an array of industries most likely affected)
      - risk_level: (e.g., "Low", "Medium", "High")

      Regulation Text:
      #{text}
    PROMPT

    begin
      response = llm.ask(prompt)
      parsed_response = JSON.parse(response.content)
      Rails.logger.info "LLM successfully extracted metadata for regulation."
      parsed_response.deep_transform_keys!(&:underscore).symbolize_keys
    rescue LLM::ApiError => e
      Rails.logger.error "LLM API Error during metadata extraction: #{e.message}"
      {} # Return empty hash on API error
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse LLM response JSON: #{e.message}. Response: #{response.content}"
      {} # Return empty hash on JSON parsing error
    rescue StandardError => e
      Rails.logger.error "An unexpected error occurred during LLM metadata extraction: #{e.message}"
      {} # Catch any other unexpected errors
    end
  end

end
