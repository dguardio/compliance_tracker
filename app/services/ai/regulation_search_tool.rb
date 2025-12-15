module Ai
  class RegulationSearchTool < RubyLLM::Tool
    description "Retrieves relevant compliance requirements and regulations based on a semantic search query. Use this to grounding your answers in real laws."
    
    param :query, type: :string
    
    def execute(query:)
      # 1. Generate embedding for the query
      embedding = Ai::EmbeddingService.generate(query)
      
      return "Error: Could not generate embedding for query." unless embedding

      # 2. Search StandardRequirements and Regulations
      requirements = StandardRequirement.nearest_neighbors(:embedding, embedding, distance: "euclidean").limit(3).includes(:regulation)
      regulations = Regulation.nearest_neighbors(:embedding, embedding, distance: "euclidean").limit(2)

      return "No relevant regulations found." if requirements.empty? && regulations.empty?

      # 3. Format results context for the LLM
      results = []
      
      regulations.each do |reg|
        results << <<~RESULT
          [Document] #{reg.title}
          Jurisdiction: #{reg.jurisdiction}
          Summary: #{reg.metadata['summary'] || reg.title}
          ---
        RESULT
      end

      requirements.each do |req|
        results << <<~RESULT
          [Requirement] #{req.name} (from #{req.regulation.title})
          Content: #{req.description}
          ---
        RESULT
      end

      results.join("\n")
    rescue => e
      Rails.logger.error "RegulationSearchTool Error: #{e.message}"
      "Error performing search: #{e.message}"
    end
  end
end
