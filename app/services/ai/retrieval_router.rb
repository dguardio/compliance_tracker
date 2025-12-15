module Ai
  class RetrievalRouter
    def extract_content(url)
      Rails.logger.info "RetrievalRouter routing: #{url}"
      
      adapter = determine_adapter(url)
      
      if adapter
        Rails.logger.info "Selected adapter: #{adapter.class.name}"
        adapter.extract(url)
      else
        Rails.logger.warn "No specific adapter found for #{url}. Falling back to standard scrape."
        # Fallback to standard HTTParty scrape via main scraper logic or return nil
        nil
      end
    end

    private

    def determine_adapter(url)
      uri = URI.parse(url)
      
      # 1. Cloud Storage/Docs (Google Drive, SharePoint, etc.)
      if adaptive_domain?(uri.host, ['drive.google.com', 'docs.google.com', 'sharepoint.com', 'dropbox.com'])
        return Ai::Adapters::DocumentDiver.new
      end

      # 2. Specific File Formats (PDF, XML, DOCX) usually ending in extension
      path = uri.path.downcase
      if path.end_with?('.pdf', '.xml', '.docx', '.doc')
        return Ai::Adapters::FormatSpecialist.new
      end

      # 3. Dynamic Web Content (SPA/Javascript heavy) - Heuristic or specific list
      # For now, default to WebWalker for any generic web page if standard scraping failed previously,
      # but as a primary router, we might use it for everything or specific "hard" sites.
      # Let's assign it if it's not a file or cloud doc.
      return Ai::Adapters::WebWalker.new
    end

    def adaptive_domain?(host, domains)
      return false if host.blank?
      domains.any? { |d| host.include?(d) }
    end
  end
end
