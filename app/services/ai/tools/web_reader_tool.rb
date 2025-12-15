module Ai
  module Tools
    class WebReaderTool < RubyLLM::Tool
      description "Reads the content of a specific web page URL."
      param :url, desc: "The URL to read"

      def execute(url:)
        Rails.logger.info "🤖 Agent reading URL: #{url}"
        
        begin
          response = HTTParty.get(url, timeout: 10)
          return "Error: Could not fetch page (Status #{response.code})" unless response.success?
          
          # Simple extraction
          doc = Nokogiri::HTML(response.body)
          
          # Remove noise
          doc.css('script, style, nav, footer, iframe').remove
          
          text = doc.text.squish
          
          # Truncate to avoid context window explosion (though Gemini Pro is huge, being safe)
          text.truncate(20_000, separator: ' ')
        rescue => e
          "Error reading page: #{e.message}"
        end
      end
    end
  end
end
