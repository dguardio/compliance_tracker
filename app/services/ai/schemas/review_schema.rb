module Ai
  module Schemas
    # Schema for policy review results.
    # Used by PolicyReviewerAgent.
    #
    class ReviewSchema < RubyLLM::Schema
      number :overall_score, description: "Overall policy quality score 0-100"
      string :summary,       description: "Brief summary of the review findings"

      array :findings do
        object do
          string :section,     description: "Section of the policy with the issue"
          string :severity,    description: "Severity: info, low, medium, high, critical"
          string :finding,     description: "Description of the issue found"
          string :recommendation, description: "Suggested fix or improvement"
        end
      end

      array :strengths do
        string description: "A strength or well-written aspect of the policy"
      end
    end
  end
end
