module Ai
  class FilterAgent
    BATCH_SIZE = 10

    # Classify a single candidate (backward compatible)
    # Accepts either hash with :title/:snippet keys or keyword args
    def relevant?(candidate = nil, title: nil, snippet: nil)
      if candidate.is_a?(Hash)
        title ||= candidate[:title]
        snippet ||= candidate[:snippet]
      end

      return false if title.blank?

      results = relevant_batch?([{ title: title, snippet: snippet }])
      results.first
    rescue => e
      Rails.logger.error "[FilterAgent] Classification failed: #{e.message}"
      true # Fail open — don't miss compliance items
    end

    # Classify multiple candidates in a single LLM call
    # Returns array of booleans in the same order as input
    def relevant_batch?(candidates)
      return [] if candidates.empty?

      # Process in batches
      candidates.each_slice(BATCH_SIZE).flat_map do |batch|
        classify_batch(batch)
      end
    end

    private

    def classify_batch(batch)
      candidate_list = batch.each_with_index.map do |c, i|
        "#{i}. Title: #{c[:title]}\n   Snippet: #{c[:snippet].to_s.truncate(200)}"
      end.join("\n\n")

      prompt = <<~PROMPT
        You are a regulatory document classifier. For each numbered document below, 
        determine if it is a regulation, law, standard, official guidance, or compliance-related document.

        Mark as is_regulation: true if it IS a regulatory/compliance document.
        Mark as is_regulation: false if it is news, opinion, blog post, marketing, job posting, 
        meeting agenda, procurement notice, or irrelevant.

        Documents:
        #{candidate_list}
      PROMPT

      response = Ai::Client.chat_with_schema(
        prompt,
        Ai::Schemas::FilterBatchSchema,
        task_type: :classifier,
        agent_name: "FilterAgent"
      )

      # Parse schema response — guaranteed to have results array
      content = response.content
      if content.is_a?(Hash) && content['results']
        result_map = {}
        content['results'].each { |r| result_map[r['index'].to_i] = r['is_regulation'] }
        batch.each_index.map { |i| result_map.fetch(i, true) }
      else
        batch.map { true } # Fail open
      end
    rescue => e
      Rails.logger.error "[FilterAgent] Batch classification failed: #{e.message}"
      batch.map { true } # Fail open
    end
  end
end
