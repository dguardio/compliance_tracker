module Ai
  module Schemas
    # Schema for regulation metadata extraction.
    # Used by MetadataExtractorAgent and RegulationProcessorService.
    #
    class MetadataSchema < RubyLLM::Schema
      string :title,          description: "The official title of the regulation"
      string :agency,         description: "The issuing regulatory agency or body"
      string :jurisdiction,   description: "Geographic jurisdiction (e.g., US, EU, California)"
      string :effective_date, description: "Effective or enforcement date in YYYY-MM-DD format"
      string :publication_date, description: "Publication date in YYYY-MM-DD format"
      string :reg_type,       description: "Type: regulation, law, standard, guidance, directive"
      string :risk_level,     description: "Risk level: low, medium, high, critical"
      string :summary,        description: "Brief 2-3 sentence summary of the regulation"

      array :keywords do
        string description: "Relevant keyword or topic"
      end

      array :sectors do
        string description: "Applicable industry sector (e.g., finance, healthcare, technology)"
      end
    end
  end
end
