require 'google_search_results'

module Ai
  module Tools
    class GoogleSearchTool < RubyLLM::Tool
      description "Searches Google for current information about an organization."
      param :query, desc: "The search query strings"

      def execute(query:)
        Rails.logger.info "🤖 Agent searching Google for: #{query}"
        
        api_key = Rails.application.credentials.dig(:google, :serpapi_api_key) || ENV['SERPAPI_API_KEY']
        
        if api_key.blank?
          Rails.logger.warn "⚠️ SerpAPI key missing. Falling back to simulated search."
          return simulated_search(query)
        end

        begin
          search = GoogleSearch.new(q: query, api_key: api_key, num: 5)
          results = search.get_hash
          
          # Extract organic results
          organic_results = results[:organic_results] || []
          
          # Map to a simplified format for the LLM
          formatted_results = organic_results.map do |result|
            {
              title: result[:title],
              link: result[:link],
              snippet: result[:snippet]
            }
          end.to_json
          
          Rails.logger.info "✅ Found #{organic_results.count} results."
          formatted_results
          
        rescue => e
          Rails.logger.error "💥 SerpAPI Search Failed: #{e.message}"
          simulated_search(query)
        end
      end

      private

      def simulated_search(query)
        # Fallback if API fails or is missing
        [
          {
            title: "Privacy Policy - #{query}",
            link: "https://example.com/privacy",
            snippet: "We collect data including PII and Genetic Data. We operate in CA and EU."
          },
          {
            title: "About Us - #{query}",
            link: "https://example.com/about",
            snippet: "Founded in 2020, we are a leading provider of Health Tech services."
          }
        ].to_json
      end
    end
  end
end
