class AiSearchService
  def self.expand_query(term)
    return [] if term.blank?

    prompt = <<~PROMPT
      Generate 5-7 relevant keywords or synonyms for the search term: "#{term}"
      Context: Regulatory compliance, law, and business operations.
      
      Return ONLY a JSON array of strings. Example: ["keyword1", "keyword2"]
    PROMPT

    begin
      response = RubyLLM.chat.ask(prompt)
      # Clean up response if it contains markdown code blocks
      content = response.content.gsub(/```json|```/, '').strip
      JSON.parse(content)
    rescue => e
      Rails.logger.error("AI Search Expansion failed: #{e.message}")
      []
    end
  end
end
