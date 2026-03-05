class TestSample < ApplicationRecord
  belongs_to :test_execution

  # Enums
  enum result: {
    not_tested: 0,
    pass: 1,
    fail: 2,
    not_applicable: 3
  }, _prefix: true

  # Validations
  validates :sample_identifier, presence: true
  validates :result, presence: true

  # Scopes
  scope :passed, -> { where(result: :pass) }
  scope :failed, -> { where(result: :fail) }
  scope :tested, -> { where.not(result: :not_tested) }
end
