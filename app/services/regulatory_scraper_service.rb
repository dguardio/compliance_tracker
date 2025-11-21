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

    regulation_links_data.each do |link_data|
      process_regulation_link(link_data[:url], data_source.provider, link_data[:title], link_data[:publication_date])
    end
  end

  def scrape_rss_feed(data_source)
    response = HTTParty.get(data_source.url, timeout: 30)
    unless response.success?
      Rails.logger.error "Failed to fetch RSS feed for #{data_source.name}: #{response.code} - #{response.message}"
      return
    end

    feed = RSS::Parser.parse(response.body, false)
    Rails.logger.info "Processing RSS feed: #{feed.channel.title} with #{feed.items.size} items."

    feed.items.each do |item|
      process_regulation_link(item.link, data_source.provider, item.title, item.pubDate.to_date)
    end
  end

  def scrape_api(data_source)
    Rails.logger.warn "API scraping not yet implemented for data source: #{data_source.name}. Add custom logic based on API structure defined in settings."
    # Placeholder for API logic.
    # response = HTTParty.get(data_source.url, headers: data_source.settings['headers'])
    # ... parsing logic based on settings ...
  end

  # Processes a link to a potential regulation, handling different content types.
  def process_regulation_link(url, provider, title = nil, publication_date = nil)
    Rails.logger.info "Attempting to process regulation link: #{url}"
    
    regulation_response = HTTParty.get(url, timeout: 60)
    unless regulation_response.success?
      Rails.logger.error "Failed to fetch regulation resource #{url}: #{regulation_response.code}"
      return
    end

    content_type = regulation_response.headers['Content-Type']
    extracted_text = extract_text_from_response(regulation_response, content_type)

    if extracted_text.blank?
      Rails.logger.warn "Could not extract text from resource at #{url} with content type #{content_type}"
      return
    end

    attributes = build_regulation_attributes(extracted_text, url, provider, title, publication_date, content_type)
    existing_regulation = Regulation.find_by(external_id: url)

    if existing_regulation
      handle_existing_regulation(existing_regulation, attributes)
    else
      handle_new_regulation(attributes)
    end
  rescue HTTParty::Error, SocketError, URI::InvalidURIError => e
    Rails.logger.error "Error fetching or processing regulation from #{url}: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "An unexpected error occurred while processing regulation link #{url}: #{e.message}"
  end

  # Builds a hash of attributes for a new regulation.
  def build_regulation_attributes(text, url, provider, title, publication_date, content_type)
    {
      title: title.presence || "Untitled Regulation from #{provider.name}",
      agency: provider.name,
      jurisdiction: provider.jurisdiction,
      reg_type: 'unknown',
      publication_date: publication_date.presence || Date.current,
      status: 'pending_review',
      full_text: { extracted_content: text },
      files: { original_url: url, content_type: content_type },
      metadata: { content_hash: Digest::SHA256.hexdigest(text) },
      external_id: url
    }
  end

  # Handles the logic for creating a new regulation.
  def handle_new_regulation(attributes)
    Rails.logger.info "Creating first version for regulation at #{attributes[:external_id]}."
    new_regulation = Regulation.new(attributes.merge(version: 1))

    if new_regulation.save
      Rails.logger.info "Successfully saved new regulation: #{new_regulation.title} (ID: #{new_regulation.id}). Enqueuing for processing."
      ProcessRegulationJob.perform_later(new_regulation.id)
    else
      Rails.logger.error "Failed to save new regulation from #{attributes[:external_id]}: #{new_regulation.errors.full_messages.join(', ')}"
    end
  end

  # Handles the logic for updating an existing regulation (creating a new version).
  def handle_existing_regulation(existing_regulation, attributes)
    if existing_regulation.metadata['content_hash'] != attributes[:metadata][:content_hash]
      Rails.logger.info "Content changed for regulation at #{attributes[:external_id]}. Creating a new version."
      
      new_regulation = Regulation.new(
        attributes.merge(
          version: existing_regulation.version + 1,
          previous_version_id: existing_regulation.id
        )
      )

      if new_regulation.save
        existing_regulation.update(status: 'superseded')
        Rails.logger.info "Successfully created new version #{new_regulation.version} for regulation #{new_regulation.id}."
        ProcessRegulationJob.perform_later(new_regulation.id)
      else
        Rails.logger.error "Failed to save new version for regulation from #{attributes[:external_id]}: #{new_regulation.errors.full_messages.join(', ')}"
      end
    else
      Rails.logger.info "Regulation from #{attributes[:external_id]} already exists and content has not changed."
    end
  end

  # Extracts text from the HTTP response based on its content type.
  def extract_text_from_response(response, content_type)
    case content_type
    when /text\/html/
      Nokogiri::HTML(response.body).at('body')&.text&.strip
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

  # Extracts regulation links from raw HTML using an LLM.
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
      response = LLM.ask(prompt)
      parsed_response = JSON.parse(response.content)
      
      unless parsed_response.is_a?(Array)
        Rails.logger.error "LLM response for link extraction was not a JSON array: #{response.content}"
        return []
      end

      parsed_response.map do |item|
        item['url'] = URI.join(data_source.url, item['url']).to_s if item['url'].present?
        item['publication_date'] = Date.parse(item['publication_date']) rescue nil if item['publication_date'].present?
        item.deep_transform_keys!(&:underscore).symbolize_keys
      end
    rescue LLM::ApiError => e
      Rails.logger.error "LLM API Error during link extraction for #{data_source.provider.name}: #{e.message}"
      []
    rescue JSON::ParserError => e
      Rails.logger.error "Failed to parse LLM response JSON for link extraction: #{e.message}. Response: #{response.content}"
      []
    rescue StandardError => e
      Rails.logger.error "An unexpected error occurred during LLM link extraction for #{data_source.provider.name}: #{e.message}"
      []
    end
  end
end