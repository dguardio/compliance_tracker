module Ai
  class RegulatoryDiscoveryAgent
    # The Watchdog Agent 🐕
    # Goals:
    # 1. Proactively search for new regulations.
    # 2. Filter out noise (news, blogs).
    # 3. Deduplicate against existing data.
    # 4. Trigger ingestion for valid findings.

    MAX_ITERATIONS = 5 # Avoid infinite loops
    
    def self.run_global_scan(topics: nil)
      topics ||= default_topics
      new(topics).run
    end

    def initialize(seed_topics)
      @queue = seed_topics.dup
      @visited_urls = []
      @found_regulations = []
    end

    def run
      Rails.logger.info "🐕 Watchdog Agent Starting Global Scan..."
      
      iterations = 0
      while @queue.any? && iterations < MAX_ITERATIONS
        topic = @queue.shift
        iterations += 1
        
        Rails.logger.info "🔍 Watchdog Searching: #{topic}"
        process_topic(topic)
      end
      
      Rails.logger.info "✅ Watchdog Scan Complete. Discovered #{@found_regulations.count} new regulations."
    end

    private

    def self.default_topics
      [
        "New EU AI Act implementation guidelines 2024",
        "Upcoming GDPR amendments 2025",
        "US Federal Privacy Legislation 2025 status",
        "California Privacy Rights Act enforcement updates",
        "New FATF crypto travel rule requirements"
      ]
    end

    def process_topic(topic)
      # 1. Search (using our Google Tool)
      search_tool = Ai::Tools::GoogleSearchTool.new
      results_json = search_tool.execute(query: "#{topic} site:.gov OR site:.eu OR site:.org") # Target official domains
      
      begin
        results = JSON.parse(results_json)
      rescue JSON::ParserError
        Rails.logger.warn "⚠️ Search returned non-JSON"
        return
      end

      # 2. Analyze & Filter Results
      results.each do |result|
        url = result['link']
        next if @visited_urls.include?(url)
        @visited_urls << url
        
        next if Regulation.exists?(source_url: url) # Deduplication

        evaluate_source(url, result['snippet'])
      end
    end

    def evaluate_source(url, snippet)
      # 3. Collaborative Filtering: Use the shared FilterAgent
      candidate = { title: "Unknown (Wild Search)", url: url, snippet: snippet }
      
      # We assume the FilterAgent can handle a candidate with just these fields.
      # Ideally we scrape the title first or let the FilterAgent do a lightweight fetch.
      # For now, we trust the specific prompts inside FilterAgent or we enhance it.
      
      if Ai::FilterAgent.new.relevant?(candidate)
        Rails.logger.info "💎 Watchdog confirmed relevance for: #{url}"
        trigger_ingestion(url)
        @found_regulations << url
      else
        Rails.logger.info "🗑️ Watchdog skipped: #{url}"
      end
    rescue => e
      Rails.logger.warn "⚠️ Watchdog evaluation failed: #{e.message}"
    end

    def trigger_ingestion(url)
      Rails.logger.info "🚀 Watchdog Triggering Ingestion for #{url}"
      # Use the main scraper service to ingest a single URL
      # We pass a dummy source or nil if the service supports it.
      # If RegulatoryScraperService requires a source object, we might need a "System" source.
      
      # Trying to find a generic source or create an ad-hoc one
      source = RegulatoryDataSource.find_by(name: 'Global Watchdog') || 
               RegulatoryDataSource.create!(
                 name: 'Global Watchdog', 
                 source_type: 'web_scrape', 
                 url: 'http://completed.placeholder', 
                 provider: Provider.first_or_create!(name: 'System Discovery')
               )

      RegulatoryScraperService.new.process_regulation_link(url, source)
    end
    
    def check_for_references(title)
      # Simple heuristic: If title mentions a new Act, verify we verified it fully?
      # Or ask LLM to suggest related queries.
      # For now, simplistic.
    end
  end
end
