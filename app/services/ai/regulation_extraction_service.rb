module Ai
  class RegulationExtractionService
    def initialize(regulation, custom_column)
    @regulation = regulation
    @custom_column = custom_column
  end

  def call
    # Check if extraction already exists and is not stale
    existing = RegulationExtraction.find_by(
      regulation: @regulation,
      custom_column: @custom_column
    )
    
    return existing if existing && !existing.stale?

    # Extract data using LLM
    result = extract_with_llm
    
    # Save or update extraction
    if existing
      existing.update(result)
      existing
    else
      RegulationExtraction.create!(result.merge(
        regulation: @regulation,
        custom_column: @custom_column
      ))
    end
  end

  private

  def extract_with_llm
    full_text = @regulation.full_text['extracted_content'] || ''
    
    prompt = build_prompt(full_text)
    
    begin
      response = RubyLLM.chat.ask(prompt)
      # Accommodate for the LLM sometimes returning JSON in a markdown block
      content = response.content.gsub(/`{3}(json)?/, '').strip
      
      parse_response(content)
    rescue => e
      Rails.logger.error("Extraction failed for regulation #{@regulation.id}: #{e.message}")
      {
        extracted_value: 'Error: Unable to extract',
        reasoning: e.message,
        source_text: nil,
        confidence_score: 0.0
      }
    end
  end

  def build_prompt(full_text)
    <<~PROMPT
      You are analyzing a regulatory document to extract specific information.
      
      Document Title: #{@regulation.title}
      Agency: #{@regulation.agency}
      Jurisdiction: #{@regulation.jurisdiction}
      
      Full Text:
      Full Text:
      #{Ai::ContextManager.truncate(full_text, model: 'gemini-2.0-flash')}
      
      Question: #{@custom_column.prompt}
      
      Please provide your answer in the following JSON format:
      {
        "value": "Your extracted answer here",
        "reasoning": "Brief explanation of how you arrived at this answer",
        "source_text": "Relevant quote from the document that supports your answer",
        "confidence": 0.95
      }
      
      If the information is not found in the document, set value to "Not specified" and confidence to 0.0.
      Confidence should be between 0.0 and 1.0.
    PROMPT
  end

  def parse_response(response)
    # Parse JSON response from LLM
    parsed = JSON.parse(response)
    
    {
      extracted_value: parsed['value'],
      reasoning: parsed['reasoning'],
      source_text: parsed['source_text'],
      confidence_score: parsed['confidence'].to_f
    }
  rescue JSON::ParserError
    # Fallback if LLM doesn't return valid JSON
    {
      extracted_value: response.truncate(500),
      reasoning: 'Direct response (non-JSON)',
      source_text: nil,
      confidence_score: 0.5
    }
  end
end
end
