module Ai
  class DiscoverySupervisor
    def run_all
      Rails.logger.info "DiscoverySupervisor starting..."
      
      RegulatoryDataSource.enabled.find_each do |source|
        dispatch_scout(source)
      end
      
      Rails.logger.info "DiscoverySupervisor finished for all sources."
    end

    def dispatch_scout(source)
      Rails.logger.info "Dispatching scout for source: #{source.name} (#{source.source_type})"
      
      candidates = case source.source_type.to_sym
                   when :rss
                     Ai::Scouts::OfficialRegisterScout.new(source).scout
                   when :web_scrape, :api
                     # For now, we reuse the OfficialRegisterScout if it's broad enough, 
                     # or fallback to RegulatoryNewsScout if tailored.
                     # Based on plan, OfficialRegisterScout monitors RSS/APIs.
                     # RegulatoryNewsScout monitors news sites.
                     # We'll use source settings or type to prefer.
                     Ai::Scouts::OfficialRegisterScout.new(source).scout
                   else
                     Rails.logger.warn "No scout available for type: #{source.source_type}"
                     []
                   end

      Rails.logger.info "Scout returned #{candidates.size} candidates for #{source.name}."
      
      process_candidates(candidates)
    end

    private

    def process_candidates(candidates)
      candidates.each do |candidate|
        # Verify candidate using FilterAgent
        if Ai::FilterAgent.new.relevant?(candidate)
           ingest_candidate(candidate)
        else
           Rails.logger.info "Candidate filtered out: #{candidate[:title]}"
        end
      end
    end

    def ingest_candidate(candidate)
      # Trigger the standard ingestion flow
      # Candidate hash expects: { url:, title:, publication_date:, source: }
      # Since RegulatoryScraperService handles fetching, we might just call ProcessRegulationLink logic here,
      # or better, create a lightweight ingestion entry point.
      
      # For now, we call the legacy scraper's method to handle fetching/deduplication/saving
      # Ideally we'd move that logic to a stand-alone "IngestionService"
      RegulatoryScraperService.new.process_regulation_link(
        candidate[:url], 
        candidate[:source], # data_source object
        candidate[:title], 
        candidate[:publication_date]
      )
    end
  end
end
