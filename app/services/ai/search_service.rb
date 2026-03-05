module Ai
  class SearchService
    def self.expand_query(term)
    return [] if term.blank?

    # Cache expanded queries for 24 hours to avoid repeat LLM calls
    cache_key = "ai_search:expand:#{Digest::SHA256.hexdigest(term)}"
    Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      prompt = <<~PROMPT
        Generate 5-7 relevant keywords or synonyms for the search term: "#{term}"
        Context: Regulatory compliance, law, and business operations.
        
        Return ONLY a JSON array of strings. Example: ["keyword1", "keyword2"]
      PROMPT

      response = Ai::Client.chat(
        prompt,
        task_type: :factual,
        agent_name: "SearchExpander"
      )

      Ai::ResponseParser.json_array(response.content)
    end
  rescue => e
    Rails.logger.error("AI Search Expansion failed: #{e.message}")
    []
  end
end
end
