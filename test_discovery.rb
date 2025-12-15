# Test Script for Watchdog
puts "🐕 Testing Watchdog Agent..."

# Mocking Search Tool for Test
module Ai
  module Tools
    class GoogleSearchTool < RubyLLM::Tool
      def execute(query:)
        Rails.logger.info "   [MOCK SEARCH] #{query}"
        [
          {
            "title" => "New EU Regulation on AI",
            "link" => "https://europa.eu/ai-act-2024",
            "snippet" => "Official text of the AI Act..."
          }
        ].to_json
      end
    end
  end
end

# Mocking LLM Decision
module RubyLLM
  def self.chat(model:)
    MockChat.new
  end
  class MockChat
    def ask(prompt)
      OpenStruct.new(content: <<~JSON
        {
          "ingest": true,
          "title": "EU AI Act 2024",
          "reason": "Official legislation text found."
        }
      JSON
      )
    end
  end
end

Ai::RegulatoryDiscoveryAgent.run_global_scan(topics: ["EU AI Regulation"])
puts "✅ Test Complete."
