require 'selenium-webdriver'

module Ai
  module Adapters
    class WebWalker
      def extract(url)
        # Configure headless chrome
        options = Selenium::WebDriver::Chrome::Options.new
        options.add_argument('--headless')
        options.add_argument('--disable-gpu')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')

        driver = Selenium::WebDriver.for :chrome, options: options
        
        begin
          Rails.logger.info "WebWalker visiting: #{url}"
          driver.get(url)
          
          # Wait for body to be present (basic SPA support)
          wait = Selenium::WebDriver::Wait.new(timeout: 10)
          wait.until { driver.find_element(tag_name: 'body') }

          # Optional: Scroll to bottom to trigger lazy loading
          driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
          sleep 1 # Brief pause for lazy load
          
          # Extract main content
          # Naive approach: get body text. 
          # Better approach: Extract Readability-like content or specific selectors.
          # For generic regulation sites, body text is usually okay as we have the Supervisor to clean it.
          
          title = driver.title
          text = driver.find_element(tag_name: 'body').text
          
          {
            title: title,
            full_text: text,
            content_type: 'text/html' # Processed HTML
          }
        rescue => e
          Rails.logger.error "WebWalker failed for #{url}: #{e.message}"
          nil
        ensure
          driver.quit if driver
        end
      end
    end
  end
end
