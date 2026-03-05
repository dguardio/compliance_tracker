module Ai
  class EmbeddingService
    # Generates embeddings for a single string or an array of strings.
    # Delegates to Ai::Client to get automatic tracing, token, and cost tracking.
    def generate(text_or_array)
      return nil if text_or_array.blank?
      Ai::Client.embed(text_or_array, agent_name: "EmbeddingService")
    end

    def self.generate(text_or_array)
      new.generate(text_or_array)
    end
  end
end
