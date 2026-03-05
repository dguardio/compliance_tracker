# frozen_string_literal: true

require 'tempfile'
require 'pdf-reader'
require 'docx'
require 'rss'

# Service to scrape regulatory websites and ingest regulations.
class RegulatoryScraperService
  # Main entry point to scrape all configured data sources.
  def scrape_all
    Rails.logger.info 'Starting scrape for all enabled regulatory data sources.'
    data_sources = RegulatoryDataSource.enabled.includes(:provider)

    data_sources.each do |data_source|
      scrape_data_source(data_source)
    end

    Rails.logger.info 'Finished scraping all regulatory data sources.'
  end

  # Scrapes a single data source based on its type.
  #
  # @param data_source [RegulatoryDataSource] The data source to scrape.
  def scrape_data_source(data_source)
    Rails.logger.info "Scraping data source: #{data_source.name} (Type: #{data_source.source_type})"
    
    begin
      case data_source.source_type.to_sym
      when :web_scrape
        scrape_website(data_source)
      when :rss
        scrape_rss_feed(data_source)
      when :api
        scrape_api(data_source)
      else
        Rails.logger.warn "Unsupported source type: #{data_source.source_type} for data source ##{data_source.id}"
      end
    rescue HTTParty::Error, SocketError, URI::InvalidURIError => e
      Rails.logger.error "Error fetching or processing data for #{data_source.name} from #{data_source.url}: #{e.message}"
      data_source.update(status: :error)
    rescue StandardError => e
      Rails.logger.error "An unexpected error occurred during scraping for #{data_source.name}: #{e.message}"
      data_source.update(status: :error)
    end
  end

  private

  def scrape_website(data_source)
    if data_source.settings['scraping_engine'] == 'external_scrapling'
      return dispatch_to_python_scraper(data_source)
    end

    response = HTTParty.get(data_source.url, timeout: 30)
    unless response.success?
      Rails.logger.error "Failed to fetch URL for #{data_source.name}: #{response.code} - #{response.message}"
      return
    end

    raw_html = response.body
    regulation_links_data = []

    if data_source.settings.dig('scraping_method') == 'llm'
      Rails.logger.info "Using LLM for scraping for data source: #{data_source.name}"
      regulation_links_data = extract_links_with_llm(raw_html, data_source)
    else
      Rails.logger.info "Using Nokogiri for scraping for data source: #{data_source.name}"
      doc = Nokogiri::HTML(raw_html)
      selector = data_source.settings.dig('css_selector') || 'a[href*="regulation"], a[href*="rule"], a[href*="guidance"]'
      
      doc.css(selector).each do |link|
        href = link.attr('href')
        full_url = URI.join(data_source.url, href).to_s
        regulation_links_data << { url: full_url, title: link.text.strip, publication_date: nil }
      end
    end

    # Limit to the first 10 results to conserve tokens (TODO: Remove this limit in production)
    regulation_links_data.first(10).each do |link_data|
      process_regulation_link(link_data[:url], data_source, link_data[:title], link_data[:publication_date])
    end
  end

  def dispatch_to_python_scraper(data_source)
    Rails.logger.info "Dispatching to external Python scraper for data source: #{data_source.name}"
    
    python_service_url = ENV.fetch('PYTHON_SCRAPER_URL', 'http://localhost:8000/scrape')
    webhook_url = ENV.fetch('APP_WEBHOOK_URL', 'http://localhost:3000/api/v1/ingestions/webhook')
    
    payload = {
      url: data_source.url,
      data_source_id: data_source.id,
      webhook_url: webhook_url,
      provider_name: data_source.provider.name,
      jurisdiction: data_source.provider.jurisdiction
    }

    response = HTTParty.post(
      python_service_url,
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 10
    )

    unless response.success?
      Rails.logger.error "Failed to dispatch to python scraper: #{response.code} - #{response.message}"
      data_source.update(status: :error)
      return
    end

    Rails.logger.info "Successfully dispatched to python scraper. Job accepted."
  end

  def scrape_rss_feed(data_source)
    response = HTTParty.get(data_source.url, timeout: 30)
    unless response.success?
      Rails.logger.error "Failed to fetch RSS feed for #{data_source.name}: #{response.code} - #{response.message}"
      return
    end

    feed = RSS::Parser.parse(response.body, false)
    Rails.logger.info "Processing RSS feed: #{feed.channel.title} with #{feed.items.size} items."

    # Limit to the first 10 results to conserve tokens (TODO: Remove this limit in production)
    feed.items.first(10).each do |item|
      process_regulation_link(item.link, data_source, item.title, item.pubDate.to_date)
    end
  end

  def scrape_api(data_source)
    page = 1
    max_pages = data_source.settings['max_pages'] || 5 # Safety limit
    
    loop do
      Rails.logger.info "Scraping API page #{page} for #{data_source.name}"
      
      # Build URL with pagination
      uri = URI(data_source.url)
      params = URI.decode_www_form(uri.query || '')
      
      case data_source.settings['pagination_type']
      when 'page_number'
        params << ['page', page.to_s]
      when 'offset'
        offset = (page - 1) * (data_source.settings['page_size'] || 20)
        params << ['offset', offset.to_s]
      end
      
      uri.query = URI.encode_www_form(params)
      
      response = HTTParty.get(uri.to_s, timeout: 30)
      unless response.success?
        Rails.logger.error "Failed to fetch API for #{data_source.name}: #{response.code} - #{response.message}"
        break
      end

      json = JSON.parse(response.body)
      
      # Navigate to results array
      results = json
      if data_source.settings['results_key'].present?
        keys = data_source.settings['results_key'].split('.')
        results = keys.reduce(json) { |obj, key| obj&.dig(key) }
      end

      unless results.is_a?(Array)
        Rails.logger.error "API results is not an array for #{data_source.name}. Check results_key setting."
        break
      end
      
      if results.empty?
        Rails.logger.info "No more results found for #{data_source.name} at page #{page}."
        break
      end

      results.each do |item|
        # Extract fields using settings map
        item_url = item.dig(*data_source.settings['url_key'].split('.'))
        title = item.dig(*data_source.settings['title_key'].split('.'))
        pub_date_str = item.dig(*data_source.settings['publication_date_key']&.split('.'))
        
        publication_date = Date.parse(pub_date_str) rescue nil if pub_date_str.present?
        
        # Check for direct full text
        full_text = nil
        if data_source.settings['full_text_key'].present?
          full_text = item.dig(*data_source.settings['full_text_key'].split('.'))
        end

        if full_text.present?
           # Handle relative URLs if present, otherwise use a placeholder or nil
           full_url = item_url.present? ? URI.join(data_source.url, item_url).to_s : nil
           ingest_regulation(full_text, full_url, data_source, title, publication_date, 'text/plain', {}, item)
        elsif item_url.present?
          # Handle relative URLs
          full_url = URI.join(data_source.url, item_url).to_s
          process_regulation_link(full_url, data_source, title, publication_date, item)
        end
      end
      
      break if data_source.settings['pagination_type'].blank?
      break if page >= max_pages
      
      page += 1
    end
  end

  def process_regulation_link(url, data_source, title = nil, publication_date = nil, raw_data = {})
    Rails.logger.info "Attempting to process regulation link: #{url}"
    
    # Smart Caching: Check HEAD first
    begin
      head_response = HTTParty.head(url, timeout: 30)
      if head_response.success?
        existing_regulation = Regulation.find_by(external_id: url)
        if existing_regulation
          last_modified = head_response.headers['Last-Modified']
          etag = head_response.headers['ETag']
          
          if last_modified.present? && existing_regulation.metadata['last_modified'] == last_modified
            Rails.logger.info "Skipping regulation at #{url}: Not modified since #{last_modified}"
            return
          end
          
          if etag.present? && existing_regulation.metadata['etag'] == etag
             Rails.logger.info "Skipping regulation at #{url}: ETag match (#{etag})"
             return
          end
        end
      end
    rescue => e
      Rails.logger.warn "HEAD request failed for #{url}: #{e.message}. Proceeding with GET."
    end
    
    regulation_response = HTTParty.get(url, timeout: 60)
    unless regulation_response.success?
      Rails.logger.error "Failed to fetch regulation resource #{url}: #{regulation_response.code}"
      return
    end

    content_type = regulation_response.headers['Content-Type']
    
    if content_type.include?('text/html')
      extracted_data = extract_content_with_llm(regulation_response.body)
      return if extracted_data.blank?
      
      title = extracted_data[:title]
      publication_date = extracted_data[:publication_date]
      extracted_text = extracted_data[:full_text]
    else
      extracted_text = extract_text_from_response(regulation_response, content_type)
    end

    if extracted_text.blank?
      Rails.logger.warn "Could not extract text from resource at #{url} with content type #{content_type}"
      return
    end

    ingest_regulation(extracted_text, url, data_source, title, publication_date, content_type, regulation_response.headers, raw_data)
  rescue HTTParty::Error, SocketError, URI::InvalidURIError => e
    Rails.logger.error "Error fetching or processing regulation from #{url}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "An unexpected error occurred while processing regulation link #{url}: #{e.message}"
  end

  def ingest_regulation(text, url, data_source, title, publication_date, content_type, headers = {}, raw_data = {})
    attributes = build_regulation_attributes(text, url, data_source.provider, title, publication_date, content_type, headers, raw_data)
    
    # If URL is nil (direct text), we need a way to identify existing regulations. 
    # For now, we'll require a URL/External ID even for direct text to handle updates/drift.
    # If external_id is missing, we might need to generate one or use title (risky).
    if url.blank?
      Rails.logger.warn "Skipping ingestion: No external_id (URL) provided for regulation '#{title}'"
      return
    end

    existing_regulation = Regulation.find_by(external_id: url)

    if existing_regulation
      handle_existing_regulation(existing_regulation, attributes)
    else
      handle_new_regulation(attributes)
    end
  end

  def extract_content_with_llm(html_content)
    doc = Nokogiri::HTML(html_content)
    doc.css('script, style, header, footer, nav').remove
    cleaned_html = doc.at('body')&.inner_html || ''

    prompt = <<~PROMPT
      You are an expert in regulatory document analysis. From the following HTML content, please extract the following information:
      1.  The main title of the regulation.
      2.  The publication date of the regulation.
      3.  The full text of the regulation.

      Return the data as a JSON object with the keys "title", "publication_date" (in YYYY-MM-DD format), and "full_text".
      If any of the information is not available, set the corresponding value to null.

      HTML Content:
      #{cleaned_html}
    PROMPT

    begin
      response = RubyLLM.chat.ask(prompt)
      Rails.logger.info "LLM content response: #{response.content}"
      # Accommodate for the LLM sometimes returning JSON in a markdown block
      content = response.content.gsub(/`{3}(json)?/, '').strip
      parsed_response = JSON.parse(content)
      {
        title: parsed_response['title'],
        publication_date: Date.parse(parsed_response['publication_date']),
        full_text: parsed_response['full_text']
      }
    rescue => e
      Rails.logger.error "LLM content extraction failed: #{e.message}"
      nil
    end
  end

  def build_regulation_attributes(text, url, provider, title, publication_date, content_type, headers = {}, raw_data = {})
    {
      title: title.presence || "Untitled Regulation from #{provider.name}",
      agency: provider.name,
      jurisdiction: provider.jurisdiction,
      reg_type: 'unknown',
      publication_date: publication_date.presence || Date.current,
      status: 'pending_review',
      full_text: { extracted_content: text },
      files: { original_url: url, content_type: content_type },
      metadata: { 
        content_hash: Digest::SHA256.hexdigest(text),
        last_modified: headers['Last-Modified'],
        etag: headers['ETag'],
        raw_source_data: raw_data # Store entire raw API record
      },
      external_id: url
    }
  end

  def handle_new_regulation(attributes)
    Rails.logger.info "Creating first version for regulation at #{attributes[:external_id]}."
    new_regulation = Regulation.new(attributes.merge(revision: 1))

    if new_regulation.save
      Rails.logger.info "Successfully saved new regulation: #{new_regulation.title} (ID: #{new_regulation.id}). Enqueuing for processing."
      ProcessRegulationJob.perform_later(new_regulation.id)
    else
      Rails.logger.error "Failed to save new regulation from #{attributes[:external_id]}: #{new_regulation.errors.full_messages.join(', ')}"
    end
  end

  def handle_existing_regulation(existing_regulation, attributes)
    # Check for Data Drift: Content change OR significant metadata change
    content_changed = existing_regulation.metadata['content_hash'] != attributes[:metadata][:content_hash]
    metadata_changed = existing_regulation.effective_date != attributes[:publication_date] || # Using publication_date as proxy for effective_date from source
                       existing_regulation.agency != attributes[:agency]

    if content_changed || metadata_changed
      reason = content_changed ? "Content changed" : "Metadata changed"
      Rails.logger.info "#{reason} for regulation at #{attributes[:external_id]}. Creating a new version."
      
      new_regulation = Regulation.new(
        attributes.merge(
          revision: existing_regulation.revision + 1,
          previous_version_id: existing_regulation.id
        )
      )

      if new_regulation.save
        existing_regulation.update(status: 'superseded')
        Rails.logger.info "Successfully created new version #{new_regulation.revision} for regulation #{new_regulation.id}."
        ProcessRegulationJob.perform_later(new_regulation.id)
      else
        Rails.logger.error "Failed to save new version for regulation from #{attributes[:external_id]}: #{new_regulation.errors.full_messages.join(', ')}"
      end
    else
      Rails.logger.info "Regulation from #{attributes[:external_id]} already exists and has not changed."
    end
  end

  def extract_text_from_response(response, content_type)
    case content_type
    when /application\/pdf/
      Tempfile.create(['regulation', '.pdf'], binmode: true) do |tempfile|
        tempfile.write(response.body)
        tempfile.rewind
        PDF::Reader.new(tempfile).pages.map(&:text).join("\n")
      end
    when /application\/vnd.openxmlformats-officedocument.wordprocessingml.document/ # DOCX
      Tempfile.create(['regulation', '.docx'], binmode: true) do |tempfile|
        tempfile.write(response.body)
        tempfile.rewind
        Docx::Document.open(tempfile.path).text
      end
    else
      Rails.logger.warn "Unsupported content type for text extraction: #{content_type}"
      nil
    end
  end

  def extract_links_with_llm(raw_html, data_source)
    prompt = <<~PROMPT
      You are an expert web scraper. From the following HTML content, identify and extract links that point to new regulations, rules, or official guidance documents.
      For each relevant link, extract its absolute URL, the title of the document (from the link text or surrounding elements), and if clearly visible, its publication or effective date.
      Return the output as a JSON array of objects. Each object should have 'url', 'title', and 'publication_date' (format YYYY-MM-DD, or null if not found).
      If no relevant links are found, return an empty JSON array.

      HTML Content:
      #{raw_html}
    PROMPT

    begin
      response = RubyLLM.chat.ask(prompt)
      Rails.logger.info "LLM links response: #{response.content}"
      # Accommodate for the LLM sometimes returning JSON in a markdown block
      content = response.content.gsub(/`{3}(json)?/, '').strip
      parsed_response = JSON.parse(content)
      
      unless parsed_response.is_a?(Array)
        Rails.logger.error "LLM response for link extraction was not a JSON array: #{response}"
        return []
      end

      parsed_response.map do |item|
        item['url'] = URI.join(data_source.url, item['url']).to_s if item['url'].present?
        item['publication_date'] = Date.parse(item['publication_date']) rescue nil if item['publication_date'].present?
        item.deep_transform_keys!(&:underscore).symbolize_keys
      end
    rescue => e
      Rails.logger.error "LLM link extraction failed: #{e.message}"
      []
    end
  end
end