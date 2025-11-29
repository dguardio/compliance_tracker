class ExtractCustomColumnJob < ApplicationJob
  queue_as :default

  def perform(custom_column_id)
    custom_column = CustomColumn.find(custom_column_id)
    
    Rails.logger.info("Starting extraction for custom column: #{custom_column.name}")
    
    total = Regulation.count
    processed = 0
    
    Regulation.find_each do |regulation|
      RegulationExtractionService.new(regulation, custom_column).call
      processed += 1
      
      if processed % 10 == 0
        Rails.logger.info("Extraction progress: #{processed}/#{total}")
      end
    end
    
    Rails.logger.info("Completed extraction for custom column: #{custom_column.name}")
  end
end
