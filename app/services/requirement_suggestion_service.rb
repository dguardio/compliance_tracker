# frozen_string_literal: true

class RequirementSuggestionService
  def initialize(regulation)
    @regulation = regulation
    @llm = Langchain::LLM::OpenAI.new(api_key: ENV.fetch('OPENAI_API_KEY'))
  end

  def suggest
    prompt = create_prompt
    response = @llm.chat(messages: [{ role: 'user', content: prompt }]).completion
    parse_response(response)
  end

  private

  def create_prompt
    requirement_types = ComplianceRequirement.requirement_types.keys.join(', ')
    
    <<~PROMPT
      Analyze the following regulation text and break it down into a series of actionable compliance requirements.
      For each requirement, provide a concise name, a detailed description, a priority level, and a relevant requirement type.

      Regulation Text:
      ---
      #{@regulation.content}
      ---

      Please format your response as a JSON array of objects. Each object should have the following keys:
      - "name": A short, descriptive name for the requirement.
      - "description": A more detailed explanation of what the requirement entails.
      - "priority": The priority of the requirement. Must be one of: 'low', 'medium', 'high'.
      - "requirement_type": The most appropriate type for the requirement. Must be one of: #{requirement_types}.

      Example of a single JSON object:
      {
        "name": "Data Breach Notification within 72 Hours",
        "description": "Organizations must notify the supervisory authority of a data breach within 72 hours of becoming aware of it.",
        "priority": "high",
        "requirement_type": "incident_management"
      }

      Return only the JSON array.
    PROMPT
  end

  def parse_response(response)
    begin
      suggestions = JSON.parse(response)
      suggestions.map do |suggestion|
        ComplianceRequirement.new(
          name: suggestion['name'],
          description: suggestion['description'],
          priority: suggestion['priority'],
          requirement_type: suggestion['requirement_type']
        )
      end
    rescue JSON::ParserError
      # Handle cases where the LLM response is not valid JSON
      []
    end
  end
end
