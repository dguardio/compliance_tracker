module Ai
  module Schemas
    # Schema used for robust data extraction from regulations.
    # Used by Ai::RegulationExtractionService.
    #
    class ExtractionSchema < RubyLLM::Schema
      string :extracted_value, description: "The extracted value answering the column's question"
      string :source_text,     description: "The source text from the regulation that supports this extraction"
      string :reasoning,       description: "Brief explanation of how the value was determined"
      number :confidence,      description: "Confidence score 0.0 to 1.0"
    end
  end
end
