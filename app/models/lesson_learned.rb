class LessonLearned < ApplicationRecord
  belongs_to :incident
  belongs_to :created_by, class_name: 'User', optional: true

  # Enums
  enum category: {
    process_improvement: 0,
    technology_change: 1,
    training_needed: 2,
    policy_update: 3,
    communication: 4,
    other: 5
  }, _prefix: true

  # Validations
  validates :title, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
end
