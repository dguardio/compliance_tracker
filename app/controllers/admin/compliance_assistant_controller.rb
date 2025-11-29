class Admin::ComplianceAssistantController < ApplicationController
  def chat
    question = params[:question]
    regulation_ids = params[:regulation_ids] || []
    
    # Get regulations in current context
    regulations = Regulation.where(id: regulation_ids)
    
    # Build context from regulations
    context = build_context(regulations)
    
    # Generate AI response
    response = generate_response(question, context)
    
    render json: { response: response }
  rescue => e
    Rails.logger.error("AI Assistant error: #{e.message}")
    render json: { error: "Sorry, I encountered an error. Please try again." }, status: :unprocessable_entity
  end

  private

  def build_context(regulations)
    context_parts = []
    
    regulations.limit(10).each do |reg|
      context_parts << <<~CONTEXT
        Title: #{reg.title}
        Agency: #{reg.agency}
        Jurisdiction: #{reg.jurisdiction}
        Summary: #{reg.full_text['extracted_content']&.truncate(500)}
      CONTEXT
    end
    
    context_parts.join("\n\n---\n\n")
  end

  def generate_response(question, context)
    prompt = <<~PROMPT
      You are a compliance assistant helping users analyze regulatory documents.
      
      The user is viewing the following regulations:
      
      #{context}
      
      User Question: #{question}
      
      Please provide a helpful, concise answer based on the regulations shown above.
      If the answer cannot be determined from the provided regulations, say so clearly.
      
      Keep your response under 300 words.
    PROMPT
    
    response = RubyLLM.chat.ask(prompt)
    response.content
  end
end
