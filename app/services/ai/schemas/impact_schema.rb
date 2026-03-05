module Ai
  module Schemas
    # Schema for regulatory impact analysis results.
    # Used by ImpactAnalysisAgent and ImpactPredictionService.
    #
    class ImpactSchema < RubyLLM::Schema
      number :relevance_score, description: "Relevance score 0-100 for the regulation against the organization"
      string :risk_level,      description: "Risk level: low, medium, high, critical"
      string :summary,         description: "Brief summary of the regulation's impact on the organization"

      array :impacted_areas do
        object do
          string :area,        description: "Area of impact (e.g., data processing, reporting, access control)"
          string :severity,    description: "Impact severity: low, medium, high"
          string :explanation, description: "Why this area is impacted and what changes are needed"
        end
      end

      array :recommended_actions do
        string description: "Specific recommended action to address the regulation"
      end
    end
  end
end
