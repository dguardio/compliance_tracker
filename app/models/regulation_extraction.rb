class RegulationExtraction < ApplicationRecord
  belongs_to :regulation
  belongs_to :custom_column
  
  validates :regulation_id, uniqueness: { scope: :custom_column_id }
  
  # Return the extracted value with confidence indicator
  def display_value
    if confidence_score && confidence_score < 0.7
      "#{extracted_value} ⚠️"
    else
      extracted_value
    end
  end
  
  # Check if extraction needs refresh (regulation updated after extraction)
  def stale?
    regulation.updated_at > updated_at
  end
end
