module Ai
  # Service extracted from Admin::ComplianceAssistantController.
  # Centralizes the compliance assistant logic and uses Ai::Client
  # for all LLM interactions.
  #
  # Usage:
  #   service = Ai::ComplianceAssistantService.new
  #   response = service.ask("What is GDPR?", regulation_ids: [1, 2, 3])
  #
  class ComplianceAssistantService
    SYSTEM_INSTRUCTIONS = <<~INSTRUCTIONS
      You are a compliance assistant helping users analyze regulatory documents.
      You provide clear, concise, and accurate answers based on the regulatory context provided.
      If the answer cannot be determined from the provided regulations, say so clearly.
      Always cite which regulation your answer is based on.
      Keep your responses under 300 words unless the user asks for more detail.
    INSTRUCTIONS

    def initialize(organization: nil)
      @organization = organization
    end

    # Ask a question with optional regulation context
    #
    # @param question [String] The user's question
    # @param regulation_ids [Array<Integer>] IDs of regulations to use as context
    # @return [String] The AI-generated response
    def ask(question, regulation_ids: [])
      regulations = Regulation.where(id: regulation_ids).limit(10)
      context = build_context(regulations)

      prompt = <<~PROMPT
        #{SYSTEM_INSTRUCTIONS}

        The user is viewing the following regulations:

        #{context}

        User Question: #{question}

        Please provide a helpful, concise answer based on the regulations shown above.
      PROMPT

      response = Ai::Client.chat(
        prompt,
        task_type: :analysis,
        agent_name: "ComplianceAssistant",
        temperature: 0.3
      )

      response.content
    end

    private

    def build_context(regulations)
      return "No regulations selected." if regulations.empty?

      regulations.map do |reg|
        summary = reg.full_text.is_a?(Hash) ? reg.full_text['extracted_content']&.truncate(500) : reg.full_text.to_s.truncate(500)
        <<~CONTEXT
          Title: #{reg.title}
          Agency: #{reg.agency}
          Jurisdiction: #{reg.jurisdiction}
          Summary: #{summary}
        CONTEXT
      end.join("\n---\n\n")
    end
  end
end
