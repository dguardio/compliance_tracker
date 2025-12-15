module Ai
  module Agents
    class PolicyReviewerAgent
      # Reviews a draft policy for compliance gaps.
      # @param policy_content [String] The draft policy text
      # @param topic [String] The topic of the policy
      def run(policy_content:, topic:)
        Rails.logger.info "PolicyReviewerAgent reviewing..."

        # 1. Research: Get regulations related to this topic
        search_results = Ai::RegulationSearchTool.new.execute(query: topic)
        
        # 2. Review phase
        prompt = <<~PROMPT
          You are a strict internal Auditor. Review the following draft policy against the provided regulations.
          
          Draft Policy:
          #{policy_content}
          
          Relevant Regulations:
          #{search_results}
          
          Identify any gaps, missing requirements, or vague statements. 
          Provide a score (0-100) and a list of specific recommendations for improvement.
          
          Return JSON format:
          {
            "score": 85,
            "summary": "Good draft but missing...",
            "findings": [
               { "severity": "High", "issue": "...", "recommendation": "..." }
            ]
          }
        PROMPT

        response = RubyLLM.chat.ask(prompt)
        content = response.content.gsub(/`{3}(json)?/, '').strip
        JSON.parse(content).deep_transform_keys!(&:underscore).deep_symbolize_keys
      rescue => e
        Rails.logger.error "PolicyReviewerAgent failed: #{e.message}"
        { score: 0, summary: "Error during review: #{e.message}", findings: [] }
      end
    end
  end
end
