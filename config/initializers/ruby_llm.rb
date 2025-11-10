# frozen_string_literal: true

# This file is for configuring the ruby_llm gem.
# It sets up the default provider and API keys.

# Fetch the API key from Rails credentials.
# Make sure to add the key to your credentials file by running:
# `rails credentials:edit`
#
# And adding the following structure:
#
# google:
#   gemini_api_key: YOUR_API_KEY_HERE
#
gemini_api_key = Rails.application.credentials.dig(:google, :gemini_api_key)

if gemini_api_key.blank?
  Rails.logger.warn 'Google Gemini API key is not set in credentials. The AI service will not be available.'
else
  LLM.configure do |config|
    # Set the default provider to Google.
    config.provider = :google
    
    # Configure the Google provider with the API key.
    config.providers[:google].api_key = gemini_api_key
    
    # Set default options for the Google provider.
    config.providers[:google].default_model = 'gemini-1.5-pro-latest' # Or 'gemini-pro' for older versions
    config.providers[:google].default_options = {
      temperature: 0.3, # Lower temperature for more deterministic output
      max_tokens: 4096 # Adjust based on expected response length
    }
  end
  
  Rails.logger.info 'LLM service configured with Google Gemini as the provider.'
end
