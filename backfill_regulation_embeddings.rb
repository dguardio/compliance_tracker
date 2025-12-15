# Backfill Regulation Embeddings and Summaries
# Usage: bin/rails runner backfill_regulation_embeddings.rb

require 'ruby_llm'

puts "Starting Regulation backfill..."
puts "Total Regulations: #{Regulation.count}"

Regulation.find_each do |reg|
  puts "\nProcessing: #{reg.title} (ID: #{reg.id})"

  # 1. Check for Summary
  if reg.metadata['summary'].blank?
    puts " - Missing summary. Generating..."
    
    # Simple prompt to generate summary from full text or main text
    text_source = reg.main_text.presence || reg.full_text.to_s
    # Truncate to avoid context limits if very large
    truncated_text = text_source[0..20000] 

    prompt = <<~PROMPT
      Provide a concise 1-paragraph summary (max 150 words) of the following regulation. Focus on its purpose, scope, and key obligations.
      
      Regulation: #{reg.title}
      Text: #{truncated_text}
    PROMPT

    begin
      response = RubyLLM.chat.ask(prompt)
      summary = response.content.strip
      
      # Update metadata directly
      reg.metadata['summary'] = summary
      puts " - Summary generated: #{summary[0..50]}..."
    rescue => e
      puts " ! Failed to generate summary: #{e.message}"
      next
    end
  else
    puts " - Summary exists."
  end

  # 2. Save to trigger embedding generation (via before_save callback)
  # We force a save even if only metadata changed
  if reg.save
    if reg.embedding.present?
      puts " - Embedding generated successfully."
    else
      puts " ! Embedding generation failed (logic in model might have returned nil)."
    end
  else
    puts " ! Save failed: #{reg.errors.full_messages.join(', ')}"
  end
end

puts "\nBackfill complete!"
