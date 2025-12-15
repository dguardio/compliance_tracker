class GenerateEmbeddingJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(record)
    return unless record

    text_to_embed = case record
                    when Regulation
                      record.metadata['summary'].presence || record.title
                    when StandardRequirement
                      record.description
                    else
                      nil
                    end

    return if text_to_embed.blank?

    vector = Ai::EmbeddingService.generate(text_to_embed)
    
    if vector
      # Neighbor gem may expect raw array or string depending on setup, 
      # but sticking to array updates is safe with neighbor/pgvector gem.
      # If previous code used string interpolation "[...]", we can try passing the array directly 
      # as modern pgvector gem handles it.
      record.update_column(:embedding, vector)
    end
  rescue => e
    Rails.logger.error "GenerateEmbeddingJob failed for #{record.class} #{record.id}: #{e.message}"
    raise e # Re-raise to trigger retry_on
  end
end
