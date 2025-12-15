require 'rss'

module Ai
  module Scouts
    class OfficialRegisterScout
      def initialize(data_source)
        @data_source = data_source
      end

      def scout
        case @data_source.source_type
        when 'rss'
          fetch_rss_feed
        when 'api'
          fetch_from_api
        else
          []
        end
      rescue => e
        Rails.logger.error "OfficialRegisterScout failed for #{@data_source.name}: #{e.message}"
        []
      end

      private

      def fetch_rss_feed
        response = HTTParty.get(@data_source.url, timeout: 30)
        return [] unless response.success?

        feed = RSS::Parser.parse(response.body, false)
        return [] unless feed

        feed.items.first(10).map do |item|
          {
            url: item.link,
            title: item.title,
            publication_date: item.pubDate.to_date,
            source: @data_source,
            snippet: item.description 
          }
        end
      end

      def fetch_from_api
        results = []
        page = 1
        max_pages = @data_source.settings['max_pages'] || 3

        loop do
          break if page > max_pages

          uri = URI(@data_source.url)
          params = URI.decode_www_form(uri.query || '')
          
          # Pagination
          if @data_source.settings['pagination_type'] == 'page_number'
            params << ['page', page.to_s]
          elsif @data_source.settings['pagination_type'] == 'offset'
             offset = (page - 1) * (@data_source.settings['page_size'] || 20)
             params << ['offset', offset.to_s]
          end
          
          uri.query = URI.encode_www_form(params)

          headers = {}
          if @data_source.api_key.present?
             header_name = @data_source.settings['auth_header'] || 'Authorization'
             header_value = @data_source.settings['auth_prefix'] ? "#{@data_source.settings['auth_prefix']} #{@data_source.api_key}" : @data_source.api_key
             headers[header_name] = header_value
          end

          response = HTTParty.get(uri.to_s, headers: headers, timeout: 30)
          break unless response.success?

          json = JSON.parse(response.body)
          items = navigate_to_results(json)
          
          break if items.empty?

          items.each do |item|
             results << parse_api_item(item)
          end

          page += 1
        end

        results.compact
      end

      def navigate_to_results(json)
        return json if json.is_a?(Array)
        
        keys = (@data_source.settings['results_key'] || '').split('.')
        keys.reduce(json) { |obj, key| obj&.dig(key) } || []
      end

      def parse_api_item(item)
        url_key = @data_source.settings['url_key']
        title_key = @data_source.settings['title_key']
        date_key = @data_source.settings['publication_date_key']
        
        return nil unless url_key && title_key

        url = item.dig(*url_key.split('.'))
        title = item.dig(*title_key.split('.'))
        date_str = date_key ? item.dig(*date_key.split('.')) : nil
        
        return nil if url.blank?

        # Handle relative URLs
        full_url = url.start_with?('http') ? url : URI.join(@data_source.url, url).to_s

        {
          url: full_url,
          title: title,
          publication_date: (Date.parse(date_str) rescue nil),
          source: @data_source,
          snippet: item.to_json # Store raw item as snippet for filter agent
        }
      end
    end
  end
end
