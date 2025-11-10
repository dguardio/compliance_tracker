# frozen_string_literal: true

source 'https://rubygems.org'

ruby "3.2.1" # rubocop:disable Style/StringLiterals

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.5", ">= 7.1.5.1" # rubocop:disable Style/StringLiterals

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'

# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'

# Use Redis adapter to run Action Cable in production
gem 'redis', '>= 4.0.1'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
gem 'kredis'

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem 'bcrypt', '~> 3.1.7'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'image_processing', '~> 1.2'

# Authentication and Authorization
gem 'devise', '~> 4.9'
gem 'devise-i18n'
gem 'omniauth', '~> 2.1'
gem 'omniauth-google-oauth2', '~> 1.1'
gem 'omniauth-saml', '~> 2.0'
gem 'pundit', '~> 2.3'
gem 'rolify', '~> 6.0'

# Multi-tenancy
gem 'acts_as_tenant', '~> 0.5'

# Background Jobs and Scheduling
gem 'sidekiq', '~> 7.0'
gem 'sidekiq-scheduler', '~> 5.0'

# Notifications and Messaging
gem 'noticed', '~> 2.0'

# Web Scraping and AI
gem 'httparty', '~> 0.21'
gem 'langchainrb', '~> 0.7'
gem 'nokogiri', '~> 1.15'
gem 'ruby-openai', '~> 6.0'

# PDF Processing
gem 'pdf-forms', '~> 1.4'
gem 'pdf-reader', '~> 2.11'

# Document Preview and Processing
gem 'activestorage-office-previewer', '~> 0.1' # Office file previews
gem 'creek', '~> 2.6' # Excel file processing (alternative)
gem 'docsplit', '~> 0.7' # Document conversion for older formats
gem 'docx', '~> 0.7' # Word document processing
gem 'pdfjs_viewer-rails', '~> 0.1' # PDF.js viewer for Rails
gem 'roo', '~> 2.10' # Excel/Spreadsheet processing
gem 'ruby-ole', '~> 1.2' # OLE file handling for older Office formats
gem 'rubyzip' # ZIP file handling for Office Open XML

# API and JSON
gem 'jsonapi-serializer', '~> 2.2'
gem 'jsonb_accessor', '~> 1.4'
gem 'rack-cors', '~> 2.0'

# Search and Indexing
gem 'elasticsearch-rails', '~> 7.0'
gem 'pg_search', '~> 2.3'
gem 'ransack', '~> 4.1'

# File Upload and Storage
gem 'aws-sdk-s3', '~> 1.0', require: false
gem 'carrierwave', '~> 2.0'

# Monitoring and Logging
gem 'lograge', '~> 0.12'
gem 'sentry-rails', '~> 5.0'
gem 'sentry-ruby', '~> 5.0'

# UI and Frontend
gem 'cable_ready', '~> 5.0'
gem 'stimulus_reflex', '~> 3.5'
gem 'tailwindcss-rails', '~> 2.3'
gem 'view_component', '~> 3.0'

# Utilities
gem 'acts_as_paranoid', '~> 0.7'
gem 'dry-monads', '~> 1.6'
gem 'dry-transaction', '~> 0.15'
gem 'dry-validation', '~> 1.10'
gem 'enumerize', '~> 2.6'
gem 'friendly_id', '~> 5.4'
gem 'interactor', '~> 3.1'
gem 'kaminari'
gem 'paper_trail', '~> 15.0'
gem 'virtus', '~> 2.0'

# Regulation Intake Feature Gems
gem 'dotenv-rails', groups: %i[development test]
gem 'pgvector'
gem 'ruby_llm'

# Testing
gem 'factory_bot_rails', '~> 6.4'
gem 'faker', '~> 3.2'
gem 'rspec-rails', '~> 6.0'
gem 'shoulda-matchers', '~> 5.1'
gem 'vcr', '~> 6.1'
gem 'webmock', '~> 3.18'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  gem 'rack-mini-profiler'

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # Development tools
  gem 'annotate', '~> 3.2'
  gem 'better_errors', '~> 2.10'
  gem 'binding_of_caller', '~> 1.0'
  gem 'brakeman', '~> 5.4'
  gem 'bullet', '~> 7.0'
  gem 'letter_opener', '~> 1.8'
  gem 'letter_opener_web', '~> 2.0'
  gem 'rubocop', '~> 1.50'
  gem 'rubocop-rails', '~> 2.19'
  gem 'rubocop-rspec', '~> 2.20'
end

group :test do
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara', '~> 3.39'
  gem 'selenium-webdriver', '~> 4.10'
  gem 'webdrivers', '~> 5.3'
end
