# frozen_string_literal: true

require 'tempfile'

require 'pdf-reader'

require 'docx'



# Service to scrape regulatory websites and ingest regulations.

class RegulatoryScraperService

  # Main entry point to scrape all configured regulatory authorities.

  def scrape_all

    Rails.logger.info 'Starting scrape for all regulatory authorities.'

    providers = Provider.regulatory_authorities.active

    

    providers.each do |provider|

      scrape_provider(provider)

    end

    

    Rails.logger.info 'Finished scraping all regulatory authorities.'

  end



  # Scrapes a single provider.

  #

  # @param provider [Provider] The provider to scrape.

  def scrape_provider(provider)

    Rails.logger.info "Scraping provider: #{provider.name} from #{provider.website}"

    

    return unless provider.website.present?

    

    begin

      response = HTTParty.get(provider.website, timeout: 30) # Increased timeout for potentially slow sites

      unless response.success?

        Rails.logger.error "Failed to fetch URL for #{provider.name}: #{response.code} - #{response.message}"

        return

      end



      raw_html = response.body

      

      regulation_links_data = []



      if provider.settings[:llm_scraping_enabled]

        Rails.logger.info "Using LLM for scraping for provider: #{provider.name}"

        regulation_links_data = extract_links_with_llm(raw_html, provider)

      else

        Rails.logger.info "Using Nokogiri for scraping for provider: #{provider.name}"

        doc = Nokogiri::HTML(raw_html)

        # This is a generic example; real implementation would need specific CSS selectors

        doc.css('a[href*="regulation"], a[href*="rule"], a[href*="guidance"]').each do |link|

          href = link.attr('href')

          full_url = URI.join(provider.website, href).to_s # Resolve relative URLs

          regulation_links_data << { url: full_url, title: link.text.strip, publication_date: nil }

        end

      end



      regulation_links_data.each do |link_data|

        process_regulation_link(link_data[:url], provider, link_data[:title], link_data[:publication_date])

      end



    rescue HTTParty::Error, SocketError, URI::InvalidURIError => e

      Rails.logger.error "Error fetching or processing data for #{provider.name} from #{provider.website}: #{e.message}"

    rescue StandardError => e

      Rails.logger.error "An unexpected error occurred during scraping for #{provider.name}: #{e.message}"

    end

  end



  private



  # Processes a link to a potential regulation, handling different content types.

  #

  # @param url [String] The URL of the regulation page/file.

  # @param provider [Provider] The provider this regulation belongs to.

  # @param title [String] Optional title from the link.

  # @param publication_date [Date] Optional publication date from the link.

  def process_regulation_link(url, provider, title = nil, publication_date = nil)

    Rails.logger.info "Attempting to process regulation link: #{url}"

    

    begin

      regulation_response = HTTParty.get(url, timeout: 60) # Longer timeout for file downloads

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



      # Check if this regulation already exists based on the URL as a unique identifier.

      regulation = Regulation.find_or_initialize_by(external_id: url)



      # Create a hash of the new content to check for changes without storing large text in memory.

      new_content_hash = Digest::SHA256.hexdigest(extracted_text)



      # Only proceed if it's a new record or the content has changed.

      if regulation.new_record? || regulation.metadata['content_hash'] != new_content_hash

        regulation.assign_attributes(

          title: title.presence || "Untitled Regulation from #{provider.name}",

          agency: provider.name,

          jurisdiction: provider.jurisdiction,

          reg_type: 'unknown', # LLM will refine this

          publication_date: publication_date.presence || Date.current,

          status: 'pending_review',

          full_text: { extracted_content: extracted_text }, # Store extracted text

          files: { original_url: url, content_type: content_type },

          metadata: { content_hash: new_content_hash } # Store hash to detect changes

        )



                if regulation.save



                  Rails.logger.info "Successfully saved/updated regulation: #{regulation.title} (ID: #{regulation.id}). Enqueuing for processing."



                  # After saving, trigger the asynchronous processing and assignment pipeline.



                  ProcessRegulationJob.perform_later(regulation.id)



                else



                  Rails.logger.error "Failed to save regulation from #{url}: #{regulation.errors.full_messages.join(', ')}"



                end

      else

        Rails.logger.info "Regulation from #{url} already exists and content has not changed."

      end



    rescue HTTParty::Error, SocketError, URI::InvalidURIError => e

      Rails.logger.error "Error fetching or processing regulation from #{url}: #{e.message}"

    rescue StandardError => e

      Rails.logger.error "An unexpected error occurred while processing regulation link #{url}: #{e.message}"

    end

  end



  # Extracts text from the HTTP response based on its content type.

  #

  # @param response [HTTParty::Response] The HTTP response.

  # @param content_type [String] The content type of the response.

  # @return [String] The extracted text.

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

    when /application\/vnd\.openxmlformats-officedocument\.wordprocessingml\.document/ # DOCX

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

  #

  # @param raw_html [String] The raw HTML content of the page.

  # @param provider [Provider] The provider associated with the page.

  # @return [Array<Hash>] An array of hashes, each with :url, :title, :publication_date.

  def extract_links_with_llm(raw_html, provider)

    llm = LLM.chat

    prompt = <<~PROMPT

      You are an expert web scraper. From the following HTML content, identify and extract links that point to new regulations, rules, or official guidance documents.

      For each relevant link, extract its absolute URL, the title of the document (from the link text or surrounding elements), and if clearly visible, its publication or effective date.

      Return the output as a JSON array of objects. Each object should have 'url', 'title', and 'publication_date' (format YYYY-MM-DD, or null if not found).

      If no relevant links are found, return an empty JSON array.



      HTML Content:

      #{raw_html}

    PROMPT



    begin

      response = llm.ask(prompt)

      parsed_response = JSON.parse(response.content)

      

      unless parsed_response.is_a?(Array)

        Rails.logger.error "LLM response for link extraction was not a JSON array: #{response.content}"

        return []

      end



      # Resolve relative URLs and ensure absolute URLs

      parsed_response.map do |item|

        item['url'] = URI.join(provider.website, item['url']).to_s if item['url'].present?

        item['publication_date'] = Date.parse(item['publication_date']) rescue nil if item['publication_date'].present?

        item.deep_transform_keys!(&:underscore).symbolize_keys

      end

    rescue LLM::ApiError => e

      Rails.logger.error "LLM API Error during link extraction for #{provider.name}: #{e.message}"

      []

    rescue JSON::ParserError => e

      Rails.logger.error "Failed to parse LLM response JSON for link extraction: #{e.message}. Response: #{response.content}"

      []

    rescue StandardError => e

      Rails.logger.error "An unexpected error occurred during LLM link extraction for #{provider.name}: #{e.message}"

      []

    end

  end
