# frozen_string_literal: true
require 'ruby_llm'

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
  RubyLLM.configure do |config|
    config.gemini_api_key = gemini_api_key
    config.model_registry_file = Rails.root.join('config', 'model_registry.json')
    config.default_model = 'gemini-2.0-flash'
  end
  
  Rails.logger.info 'LLM service configured with Google Gemini as the provider.'
end
