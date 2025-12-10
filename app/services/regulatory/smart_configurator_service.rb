module Regulatory
  class SmartConfiguratorService
    def initialize(data_source)
      @data_source = data_source
    end

    def call
      config = preview
      
      if config
        @data_source.update(
          url: config[:url],
          settings: config[:settings]
        )
      end
    end

    def preview
      return nil unless documentation_available?

      docs = fetch_documentation
      analyze_documentation(docs)
    end

    private

    def documentation_available?
      @data_source.documentation_content.present? || @data_source.documentation_url.present?
    end

    def fetch_documentation
      # Primary Method: User pasted content (Alt Method for SPA/JS pages)
      return @data_source.documentation_content if @data_source.documentation_content.present?

      # Secondary Method: Attempt to scrape URL
      if @data_source.documentation_url.present?
        begin
          response = HTTParty.get(@data_source.documentation_url)
          
          if response.success?
            body = response.body
            
            # Heuristic check for JS-only pages
            if body.length < 500 || body.downcase.include?('enable javascript')
              raise "Documentation seems to require JavaScript. Please paste the content manually."
            end

            return body
          else
            raise "Failed to fetch URL (HTTP #{response.code})"
          end
        rescue StandardError => e
          Rails.logger.error("Documentation fetch failed: #{e.message}")
          # In a real controller, we'd want this error to bubble up to the user
          raise e
        end
      end

      nil
    end

    def analyze_documentation(docs)
      return nil if docs.blank?

      prompt = <<~PROMPT
        You are an API integration expert. I need to configure a regulatory data source based on the following API documentation.
        
        Extract the following information:
        1. The API endpoint URL for fetching a list of regulations.
        2. The JSON key that holds the list of results (results_key).
        3. The JSON key for the title of a regulation item (title_key).
        4. The JSON key for the URL of a regulation item (url_key).
        5. The relevant Industry Sectors (e.g., Finance, Healthcare, Energy). If the source covers all or many sectors (like Federal Register), use "All Sectors".
        6. The relevant Jurisdiction (e.g., USA, EU, UK, Global).

        Return specific JSON ONLY with these keys: "url", "results_key", "title_key", "url_key", "sectors" (array of strings), "jurisdictions" (array of strings).
        Do not include markdown formatting like ```json ... ```. Just the raw JSON string.

        Documentation:
        #{docs[0..3000]} 
      PROMPT
      # Truncate docs to avoid token limits for this MVP

      begin
        # RubyLLM.chat.ask returns the content string directly or response object that acts like one
        content = RubyLLM.chat.ask(prompt).content
        
        # Clean up any potential markdown code blocks if the LLM ignores instructions
        clean_content = content.gsub(/```json/, '').gsub(/```/, '').strip
        
        data = JSON.parse(clean_content)
        
        {
          url: data['url'],
          sectors: data['sectors'],
          jurisdictions: data['jurisdictions'],
          settings: {
            'results_key' => data['results_key'],
            'title_key' => data['title_key'],
            'url_key' => data['url_key']
          }
        }
      rescue StandardError => e
        Rails.logger.error("Smart configuration failed: #{e.message}")
        nil
      end
    end
  end
end
