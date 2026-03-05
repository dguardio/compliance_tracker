module Ai
  class OrganizationResearchAgent
    def initialize(organization)
      @organization = organization
    end

    def self.perform_later(organization)
      # In a real app, this would be a Job. For now, we call the service.
      new(organization).run
    end

    def run
      Rails.logger.info "🕵️‍♀️ Starting Deep Research for Organization: #{@organization.name}"
      broadcast_log("🕵️‍♀️ Starting deep research for #{@organization.name}...")
      
      # Clear previous errors so the UI resets
      if @organization.settings['ai_research_error']
        @organization.update!(
          settings: @organization.settings.except('ai_research_error', 'ai_research_error_at')
        )
      end

      response = Ai::Client.agent_chat(
        research_prompt,
        tools: [Ai::Tools::GoogleSearchTool, Ai::Tools::WebReaderTool],
        instructions: system_instructions,
        agent_name: "OrganizationResearchAgent"
      )

      # 3. Process the Result
      # The model should return the final synthesis after using tools
      process_result(response.content)
      
    rescue => e
      Rails.logger.error "💥 Organization Research Failed: #{e.message}"
      broadcast_log("💥 Error: #{e.message}", type: :error)
      @organization.update!(settings: @organization.settings.merge(
        'ai_research_error' => e.message,
        'ai_research_error_at' => Time.current.iso8601
      ))
      # Broadcast error state
      Turbo::StreamsChannel.broadcast_replace_to(
        @organization,
        target: "compliance_profile_card",
        partial: "organizations/compliance_profile",
        locals: { organization: @organization, current_user: nil }
      )
    end

    private

    def broadcast_log(message, type: :info)
      color_class = case type
                    when :success then "text-green-400 font-bold"
                    when :warning then "text-yellow-400"
                    when :error   then "text-red-400 font-bold"
                    when :action  then "text-blue-400"
                    else "text-slate-300"
                    end

      Turbo::StreamsChannel.broadcast_append_to(
        @organization,
        target: "agent_trace_content",
        html: <<~HTML
          <div class="flex items-center gap-2 animate-fade-in-up">
            <span class="text-slate-600 font-light">[#{Time.current.strftime("%H:%M:%S")}]</span>
            <span class="#{color_class}">#{message}</span>
          </div>
        HTML
      )
    end

    def system_instructions
      <<~INSTRUCTIONS
        You are an expert Compliance Research Agent. Your goal is to build a "Rich Compliance Profile" for an organization by researching them on the open web.
        
        You have access to Google Search and a Web Reader.
        
        **Your Process:**
        1.  **Plan**: Decide what to search for (e.g., Privacy Policy, Jurisdictions, Products).
        2.  **Act**: Use `GoogleSearchTool` to find sources.
        3.  **Read**: Use `WebReaderTool` to read key pages (like the actual Privacy Policy).
        4.  **Refine**: If you miss info, search again with better terms.
        5.  **Synthesize**: Output the final profile.
        
        **Rules:**
        - ALWAYS verify facts by reading the page, don't just trust search snippets.
        - Capture URLs of your sources as citations.
      INSTRUCTIONS
    end

    def research_prompt
      <<~PROMPT
        Research the organization "#{@organization.name}" (Website: #{@organization.website || 'Unknown'}).
        
        I need you to determine:
        1. **Jurisdictions**: Where do they physically operate? Where do they have customers? (e.g., "US", "EU", "CA").
        2. **Industries**: What is their primary business sector? (e.g., "FinTech", "HealthCare").
        3. **Data Types**: What kind of sensitive data do they likely process? (e.g., "PHI", "PII", "Genetic Data", "Credit Card Info").
        4. **Compliance Frameworks**: What regulations likely apply? (e.g., "GDPR", "HIPAA", "CCPA", "PCI-DSS").

        **Final Output Format:**
        Please return your final answer as a JSON block wrapped in ```json``` with the following structure:
        {
          "profile": {
            "jurisdictions": ["string"],
            "industries": ["string"],
            "data_types": ["string"],
            "frameworks": ["string"],
            "summary": "string"
          },
          "report_markdown": "Detailed markdown report with links..."
        }
      PROMPT
    end

    def process_result(content)
      broadcast_log("🧠 Synthesizing findings...", type: :action)
      
      # Extract JSON
      json_match = content.match(/```json\n(.*?)\n```/m)
      
      if json_match
        data = JSON.parse(json_match[1])
        
        broadcast_log("💾 Saving compliance profile...", type: :action)
        
        # Prepare new settings
        new_settings = @organization.settings.merge(
          'ai_compliance_profile' => data['profile'],
          'ai_research_report' => data['report_markdown'],
          'last_enriched_at' => Time.current.iso8601
        )

        # Tag organization with found keywords for easier filtering
        if data['profile'] && data['profile']['industries']
           current_tags = new_settings['compliance_keywords'] || []
           # Safety check: Parse if it's a JSON string (fix for mismatch error)
           if current_tags.is_a?(String)
             begin
               current_tags = JSON.parse(current_tags)
             rescue JSON::ParserError
               current_tags = []
             end
           end
           
           new_tags = (current_tags + data['profile']['industries']).uniq
           new_settings['compliance_keywords'] = new_tags
        end
        
        # ACTUALLY SAVE THE SETTINGS!
        @organization.update!(settings: new_settings)
        Rails.logger.info "✅ Research Complete. Profile Saved."
        broadcast_log("✅ Research Complete. Profile Updated.", type: :success)
        
        # 7. Real-time Feedback via Turbo Streams ⚡
        Turbo::StreamsChannel.broadcast_replace_to(
          @organization,
          target: "compliance_profile_card",
          partial: "organizations/compliance_profile",
          locals: { organization: @organization, current_user: nil }
        )
      else
        Rails.logger.warn "⚠️ Could not parse JSON from Research Agent response."
        Rails.logger.debug content
        broadcast_log("⚠️ Could not parse structured data from AI response.", type: :warning)
      end
    end
  end
end
