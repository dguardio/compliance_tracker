module Ai
  module Agents
    class RequirementSplittingAgent
      def initialize(text)
        @text = text
      end

      def run
        return [] if @text.blank?

        prompt = <<~PROMPT
          Analyze the following regulation text and extract all specific requirements.
          
          Provide the output in a JSON format with a single key 'requirements' containing an array of objects.
          Each object should have:
          - title: Short title of the requirement.
          - description: Detailed description of what must be done.
          - entity_type: Who this requirement applies to.
          - action_type: The type of action required.
          - deadline: Specific deadline if applicable.

          Regulation Text:
          #{@text}
        PROMPT

        response = RubyLLM.chat.ask(prompt)
        content = response.content.gsub(/`{3}(json)?/, '').strip
        parsed = JSON.parse(content)
        
        # Handle cases where LLM returns root array vs object with key
        requirements = parsed.is_a?(Array) ? parsed : parsed['requirements']
        
        return [] unless requirements.is_a?(Array)
        
        requirements.map { |r| r.deep_transform_keys!(&:underscore).deep_symbolize_keys }
      rescue => e
        Rails.logger.error "RequirementSplittingAgent Error: #{e.message}"
        []
      end
    end
  end
end
