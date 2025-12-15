module Ai
  class FilterAgent
    def relevant?(candidate)
      # Simpler heuristic for now: If it has a title and URL, assume it's worth checking 
      # unless the title is obviously irrelevant. 
      # In V2, we would ask the LLM: "Is this title '#{candidate[:title]}' likely a regulation?"
      
      return false if candidate[:url].blank?
      return false if candidate[:title].blank?

      # AI Verification
      prompt = <<~PROMPT
        You are a compliance assistant. Check if the following document is likely a "Regulation", "Law", "Standard", or "Official Guidance".
        
        Title: #{candidate[:title]}
        Snippet: #{candidate[:snippet]}
        
        If it seems to be a meeting agenda, job posting, procurement notice, or news op-ed, reply "NO".
        If it is a regulatory document, reply "YES".
        
        Reply only "YES" or "NO".
      PROMPT

      response = RubyLLM.chat.ask(prompt)
      response.content.strip.upcase.include?("YES")
    rescue => e
      Rails.logger.error "FilterAgent error: #{e.message}"
      # Fail open (allow it) if AI fails, to be safe? Or fail closed? 
      # Let's fail open but log it, so we don't miss compliance items due to API errors.
      true 
    end
  end
end
