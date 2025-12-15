# Test Script for Agents
puts "1. Creating Dummy Organization..."
begin
  org = Organization.first || Organization.create!(name: "Acme Health", domain: "example.com")
  puts "   Org: #{org.name}"

  puts "\n2. Testing Research Agent (Mocked)..."
  # We define a mock response for the LLM to avoid hitting real API in test
  module RubyLLM
    def self.chat(model:)
      MockChat.new
    end
    
    class MockChat
      def with_tools(*args); self; end
      def with_instructions(*args); self; end
      def ask(prompt)
        OpenStruct.new(content: <<~JSON
          Here is the research:
          ```json
          {
            "profile": {
              "jurisdictions": ["US", "EU"],
              "industries": ["Healthcare"],
              "data_types": ["PHI"],
              "frameworks": ["HIPAA", "GDPR"],
              "summary": "Acme Health operates in US/EU."
            },
            "report_markdown": "We found evidence..."
          }
          ```
        JSON
        )
      end
    end
  end

  Ai::OrganizationResearchAgent.new(org).run
  org.reload

  puts "   Profile: #{org.settings['ai_compliance_profile']}"

  puts "\n3. Testing Impact Agent..."
  reg = Regulation.create!(title: "New HIPAA Rule", description: "Updates to PHI handling.", jurisdiction: "Federal")
  Ai::ImpactAnalysisAgent.new(org, reg).analyze

  match = OrganizationRegulation.find_by(organization: org, regulation: reg)
  puts "   Match Score: #{match&.relevance_score}"
  puts "   Match Details: #{match&.relevance_details}"
  
rescue => e
  puts "ERROR: #{e.class} - #{e.message}"
  puts e.backtrace
end
