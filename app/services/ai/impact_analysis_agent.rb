module Ai
  class ImpactAnalysisAgent
    def self.analyze_impact_for_all_orgs(regulation)
      # Process for all active organizations
      Organization.find_each do |org|
        new(org, regulation).analyze
      end
    end

    def initialize(organization, regulation)
      @organization = organization
      @regulation = regulation
    end

    def analyze
      Rails.logger.info "⚖️ Analyzing impact of Regulation ##{@regulation.id} on Org ##{@organization.id} (#{@organization.name})"

      # 1. Gather Context
      # We use the Rich Profile if available, otherwise fallback to basic info
      profile = @organization.settings['ai_compliance_profile'] || basic_profile
      
      # 2. Build Prompt
      prompt = build_prompt(profile)

      # 3. Call LLM (via Ai::Client for tracing)
      response = Ai::Client.chat(prompt, task_type: :analysis, agent_name: "ImpactAnalysisAgent")

      # 4. Process Result
      process_result(response.content)

    rescue => e
      Rails.logger.error "💥 Impact Analysis Failed: #{e.message}"
    end

    private

    def basic_profile
      {
        "summary" => "Organization Name: #{@organization.name}. No deep research profile available.",
        "industries" => [],
        "jurisdictions" => []
      }
    end

    def build_prompt(profile)
      <<~PROMPT
        You are an Expert Compliance Analyst.
        
        **Task**: Determine the relevance and impact of a Regulation on a specific Organization.
        
        **Organization Profile**:
        #{JSON.pretty_generate(profile)}
        
        **Regulation Metadata**:
        Title: #{@regulation.title}
        Jurisdiction: #{@regulation.jurisdiction}
        Topics: #{@regulation.topics.join(', ')}
        Summary: #{@regulation.description}
        
        **Regulation Text Snippet**:
        #{Ai::ContextManager.truncate(@regulation.full_text, model: 'gemini-1.5-pro', reserve_tokens: 2000)}

        **Analysis Instructions**:
        1. Compare the Organization's operations (jurisdictions, data types, industries) with the Regulation's scope.
        2. Determine a **Relevance Score** (0-100). 
           - 90-100: Direct Hit (e.g. EU company + GDPR).
           - 50-89: Likely Relevant.
           - 0-49: Low Relevance.
        3. Provide **Reasoning**. citing specific profile facts (e.g. "Relevant because org operates in EU").

        **Output Format**:
        Return JSON structure:
        {
          "relevance_score": integer,
          "reasoning": "markdown string",
          "action_required": boolean
        }
      PROMPT
    end

    def process_result(content)
      # Extract JSON
      json_match = content.match(/```json\n(.*?)\n```/m) || content.match(/\{.*\}/m)
      
      if json_match
        data = JSON.parse(json_match[0].gsub(/```json|```/, ''))
        
        # Create or Update the Match Record
        match = OrganizationRegulation.find_or_initialize_by(
          organization: @organization,
          regulation: @regulation
        )
        
        match.relevance_score = data['relevance_score']
        match.relevance_details = data['reasoning']
        match.status = data['action_required'] ? :action_required : :compliant
        
        match.save!
        
        Rails.logger.info "✅ Impact Analysis Complete. Score: #{match.relevance_score}"
      else
        Rails.logger.warn "⚠️ Could not parse JSON from Impact Agent response."
      end
    end
  end
end
