module Ai
  module Agents
    class PolicyWriterAgent
      # Drafts a policy based on a topic or specific requirement.
      # @param topic [String] The subject of the policy (e.g., "Data Retention")
      # @param context [String] Optional additional context or requirements
      def run(topic:, context: nil)
        Rails.logger.info "PolicyWriterAgent starting for topic: #{topic}"

        # 1. Research phase: Get relevant regulations
        # We reuse the search tool but adapt it to return raw text for the prompt
        search_results = Ai::RegulationSearchTool.new.execute(query: topic)
        
        # 2. Drafting phase
        prompt = <<~PROMPT
          You are a Chief Compliance Officer. Write a formal corporate compliance policy for the topic: "#{topic}".
          
          Use the following regulatory context to ensure the policy is compliant:
          #{search_results}
          
          Additional Context:
          #{context}
          
          The policy must include the following sections:
          1. Purpose
          2. Scope
          3. Definitions
          4. Policy Statements (The rules)
          5. Roles and Responsibilities
          6. Compliance and Monitoring
          
          Format the output in clean Markdown.
        PROMPT

        response = RubyLLM.chat.ask(prompt)
        response.content
      rescue => e
        Rails.logger.error "PolicyWriterAgent failed: #{e.message}"
        "Error: Could not generate policy. #{e.message}"
      end
    end
  end
end
