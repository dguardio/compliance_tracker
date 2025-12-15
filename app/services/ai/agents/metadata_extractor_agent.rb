module Ai
  module Agents
    class MetadataExtractorAgent
      def initialize(text)
        @text = text
      end

      def run
        return {} if @text.blank?

        prompt = <<~PROMPT
          Analyze the following regulation text and extract key metadata.
          
          Provide the output in a JSON format with the following keys:
          - jurisdiction: (e.g., "Federal", "California", "EU")
          - agency: (e.g., "EPA", "FDA", "SEC")
          - effective_date: (format YYYY-MM-DD, if available)
          - summary: (a concise summary of the regulation, max 200 words)
          - keywords: (an array of 5-10 relevant keywords)
          - sector: (e.g., "Healthcare", "Finance", "Technology")
          - topic: (e.g., "Data Privacy", "Environmental Compliance", "Financial Reporting")
          - risk_level: (e.g., "Low", "Medium", "High")

          Regulation Text:
          #{@text}
        PROMPT

        response = RubyLLM.chat.ask(prompt)
        content = response.content.gsub(/`{3}(json)?/, '').strip
        JSON.parse(content).deep_transform_keys!(&:underscore).deep_symbolize_keys
      rescue => e
        Rails.logger.error "MetadataExtractorAgent Error: #{e.message}"
        {}
      end
    end
  end
end
