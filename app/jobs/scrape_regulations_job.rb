# frozen_string_literal: true

# A job to scrape all regulatory authorities for new and updated regulations.
# This job is intended to be run on a schedule.
class ScrapeRegulationsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Rails.logger.info 'ScrapeRegulationsJob started.'
    RegulatoryScraperService.new.scrape_all
    Rails.logger.info 'ScrapeRegulationsJob finished.'
  end
end
