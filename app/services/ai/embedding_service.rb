module Ai
  class EmbeddingService
    def generate(text)
      return nil if text.blank?

      begin
        response = RubyLLM.embed(text)
        
        # Based on docs:
        # embedding = RubyLLM.embed("text")
        # vector = embedding.vectors
        #
        # If vector is the array of floats, we return it.
        # If it returns an array of arrays (one per input), we take the first.
        
        vectors = response.vectors
        if vectors.first.is_a?(Array)
          vectors.first
        else
          vectors
        end
      rescue => e
        Rails.logger.error("Embedding generation failed: #{e.message}")
        nil
      end
    end

    def self.generate(text)
      new.generate(text)
    end
  end
end
