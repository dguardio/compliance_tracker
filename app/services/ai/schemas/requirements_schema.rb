module Ai
  module Schemas
    # Schema for extracting individual requirements from regulation text.
    # Used by RequirementSplittingAgent.
    #
    class RequirementsSchema < RubyLLM::Schema
      array :requirements do
        object do
          string :title,             description: "Short title for this requirement"
          string :description,       description: "Full description of what is required"
          string :section_reference, description: "Section or article number in the source regulation"
          string :obligation_type,   description: "Type: mandatory, recommended, conditional, informational"
        end
      end
    end
  end
end
