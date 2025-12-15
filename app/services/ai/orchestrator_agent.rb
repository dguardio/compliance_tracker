module Ai
  class OrchestratorAgent
    # Orchestrates the creation and review of a policy.
    # @param intention [String] User's goal (e.g., "Create a policy for AI Usage")
    def execute(intention:)
      Rails.logger.info "OrchestratorAgent received intention: #{intention}"
      
      # 2. Intent Analysis (Simple keyword extraction)
      # Improved regex with word boundaries to avoid stripping letters inside words
      topic = intention.gsub(/\b(create|write|draft|policy|for|a|an|the)\b/i, '').strip
      
      Rails.logger.info "Orchestrator determined topic: #{topic}"
      
      # 2. Execution Loop
      # Step A: Write Draft
      draft = Ai::Agents::PolicyWriterAgent.new.run(topic: topic)
      
      # Step B: Review Draft
      review = Ai::Agents::PolicyReviewerAgent.new.run(policy_content: draft, topic: topic)
      
      # Step C: Refine (Optional - self-healing loop could go here)
      # For now, we return the draft and the review for the human to approve.
      
      {
        topic: topic,
        draft_content: draft,
        review_score: review[:score],
        review_findings: review[:findings]
      }
    end
  end
end
