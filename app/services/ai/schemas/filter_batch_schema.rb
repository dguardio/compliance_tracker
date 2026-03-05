module Ai
  module Schemas
    # Schema for batch document classification (FilterAgent).
    # Classifies multiple candidates in a single LLM call.
    #
    class FilterBatchSchema < RubyLLM::Schema
      array :results do
        object do
          number :index,      description: "Zero-based index of the candidate in the input list"
          boolean :is_regulation, description: "True if the document is a regulation, law, standard, or official guidance"
          string :reason,     description: "Brief reason for the classification"
        end
      end
    end
  end
end
