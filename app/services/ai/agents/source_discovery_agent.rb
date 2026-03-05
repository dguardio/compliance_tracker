module Ai
  module Agents
    class SourceDiscoveryAgent
      # Finds regulatory data sources based on sector and jurisdiction.
  def call(sector:, jurisdiction:)
    Rails.logger.info "SourceDiscoveryAgent upgrading search for: #{sector} in #{jurisdiction}"

    # 1. Broad Search using Google Tool
    query = "regulatory body for #{sector} in #{jurisdiction} official website"
    search_results_json = Ai::Tools::GoogleSearchTool.new.execute(query: query)
    
    begin
       results = JSON.parse(search_results_json)
    rescue
       return []
    end

    discovered_sources = []

    # 2. Analyze each result
    results.first(5).each do |result|
      url = result['link']
      next if url.blank?

      Rails.logger.info "Analyzing potential source: #{url}"
      
      # 3. Visit site to get context (using WebWalker for robustness)
      site_data = Ai::Adapters::WebWalker.new.extract(url)
      next unless site_data

      # 4. Classify and Extract details
      analysis = analyze_site(site_data[:title], site_data[:full_text][0..3000], url) # Limit text for token efficiency
      
      if analysis[:is_relevant]
         discovered_sources << {
           name: analysis[:name],
           url: url,
           source_type: analysis[:source_type], # rss, api, or web_scrape
           description: analysis[:description],
           sectors: [sector],
           jurisdictions: [jurisdiction],
           settings: analysis[:settings] || {} # e.g. recommended selectors
         }
      end
    end

    discovered_sources
  end

  private

  def analyze_site(title, text, url)
    prompt = <<~PROMPT
      Analyze this website to see if it is a primary source of regulations.
      
      Title: #{title}
      URL: #{url}
      Content Snippet: #{text}
      
      Task:
      1. Determine if this is a DIRECT source of regulations (Government/Official Body).
      2. Classify the best ingestion method:
         - 'rss' (if RSS feed links are prominent)
         - 'api' (if API documentation is mentioned)
         - 'web_scrape' (default)
      3. Extract the official name.
      4. Suggest a CSS selector for the main regulation links if possible.
      
      Return JSON:
      {
        "is_relevant": boolean,
        "name": "Official Name",
        "source_type": "web_scrape", 
        "description": "Short description",
        "settings": { "css_selector": "suggested_selector" }
      }
    PROMPT

    response = RubyLLM.chat.ask(prompt)
    content = response.content.gsub(/`{3}(json)?/, '').strip
    JSON.parse(content).deep_transform_keys!(&:underscore).deep_symbolize_keys
  rescue => e
    Rails.logger.error "Source Analysis failed for #{url}: #{e.message}"
    { is_relevant: false }
  end
end
  end
end
