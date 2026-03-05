class ImpactAssessment < ApplicationRecord
  belongs_to :organization
  belongs_to :regulation
  belongs_to :assessed_by, class_name: 'User', optional: true

  # Enums
  enum status: {
    pending: 0,
    analyzing: 1,
    completed: 2,
    dismissed: 3
  }, _prefix: true

  # Validations
  validates :status, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :completed_assessments, -> { where(status: :completed) }

  def impacted_items
    impact_details['items'] || []
  end

  def high_impact_items
    impacted_items.select { |i| i['impact_level'] == 'high' }
  end

  def medium_impact_items
    impacted_items.select { |i| i['impact_level'] == 'medium' }
  end

  def low_impact_items
    impacted_items.select { |i| i['impact_level'] == 'low' }
  end

  def diff_summary
    diff_data['summary'] || 'No diff available'
  end

  def diff_sections
    diff_data['sections'] || []
  end
end
