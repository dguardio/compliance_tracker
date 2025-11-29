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
    
    return if extracted_metadata.blank?

    # 3. Update the regulation record with both top-level attributes and the full metadata blob.
    update_attributes = {
      jurisdiction: extracted_metadata[:jurisdiction] || regulation.jurisdiction,
      agency: extracted_metadata[:agency] || regulation.agency,
      effective_date: extracted_metadata[:effective_date] || regulation.effective_date,
      metadata: regulation.metadata.merge(extracted_metadata)
    }
    
    if regulation.update(update_attributes)
      Rails.logger.info "Successfully updated regulation ##{regulation.id} with AI-extracted metadata."
      
      # 4. Ensure a document is attached (downloaded or generated)
      RegulationDocumentService.new.attach_document(regulation)
    else
      Rails.logger.error "Failed to update regulation ##{regulation.id}: #{regulation.errors.full_messages.join(', ')}"
    end
    
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

    prompt = <<~PROMPT
      You are an expert in regulatory compliance. Your task is to analyze the following regulation text and extract key metadata and specific requirements.
      
      Provide the output in a JSON format with the following keys:
      - jurisdiction: (e.g., "Federal", "California", "EU")
      - agency: (e.g., "EPA", "FDA", "SEC")
      - effective_date: (format YYYY-MM-DD, if available)
      - summary: (a concise summary of the regulation, max 200 words)
      - keywords: (an array of 5-10 relevant keywords)
      - sector: (e.g., "Healthcare", "Finance", "Technology")
      - topic: (e.g., "Data Privacy", "Environmental Compliance", "Financial Reporting")
      - risk_level: (e.g., "Low", "Medium", "High")
      - requirements: An array of objects, where each object represents a distinct obligation or requirement. Each object should have:
        - title: Short title of the requirement.
        - description: Detailed description of what must be done.
        - entity_type: Who this requirement applies to (e.g., "All Companies", "Healthcare Providers").
        - action_type: The type of action required (e.g., "Report", "Audit", "Policy Update").
        - deadline: Specific deadline if applicable.

      Regulation Text:
      #{text}
    PROMPT

    begin
      response = RubyLLM.chat.ask(prompt)
      # Accommodate for the LLM sometimes returning JSON in a markdown block
      content = response.content.gsub(/`{3}(json)?/, '').strip
      parsed_response = JSON.parse(content)
      Rails.logger.info "LLM successfully extracted metadata and requirements."
      parsed_response.deep_transform_keys!(&:underscore).deep_symbolize_keys
    rescue => e
      Rails.logger.error "LLM API Error or JSON parsing error during metadata extraction: #{e.message}. Response: #{response&.content}"
      {} # Return empty hash on error
    end
  end

end
