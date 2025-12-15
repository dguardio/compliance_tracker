module Ai
  class ModelRouter
    # Routes a task to the appropriate AI model based on complexity and type.
    # Currently optimized for Google Gemini models.
    
    MODELS = {
      # Fast & Cheap
      classifier: 'gemini-2.0-flash-lite',
      factual: 'gemini-2.0-flash-lite',
      
      # Smart & Reasoned (Defaulting to Flash for now per user request)
      analysis: 'gemini-2.0-flash',
      coding: 'gemini-2.0-flash', 
      drafting: 'gemini-2.0-flash' 
    }.freeze

    def route(query)
      task_type = classify_task(query)
      model_name = MODELS[task_type] || MODELS[:factual]
      
      Rails.logger.info "ModelRouter: Routed '#{query.truncate(30)}' to #{task_type} (#{model_name})"
      
      { type: task_type, model: model_name }
    end

    private

    def classify_task(query)
      # Uses the fastest model to decide where to send the heavy lifting
      prompt = <<~PROMPT
        Classify the following user query into exactly one of these categories:
        - analysis (complex reasoning, regulatory interpretation, risk assessment)
        - drafting (creating long-form content, policies, emails)
        - coding (writing software code, sql, scripts)
        - factual (simple lookup, definition, summarization, extraction)

        Return only the category name in lowercase.
        
        Query: #{query}
      PROMPT

      response = RubyLLM.chat(model: MODELS[:classifier]).ask(prompt)
      category = response.content.strip.downcase.to_sym
      
      MODELS.key?(category) ? category : :factual
    rescue => e
      Rails.logger.error "ModelRouter failed to classify: #{e.message}. Defaulting to :factual."
      :factual
    end
  end
end
