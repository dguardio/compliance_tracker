class CustomColumn < ApplicationRecord
  belongs_to :user
  has_many :regulation_extractions, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :prompt, presence: true
  validates :column_type, inclusion: { in: %w[text number date boolean] }
  
  scope :templates, -> { where(is_template: true) }
  scope :user_columns, ->(user) { where(user: user, is_template: false) }
  
  # Extract data for all regulations
  def extract_for_all_regulations
    Regulation.find_each do |regulation|
      RegulationExtractionService.new(regulation, self).call
    end
  end
end
