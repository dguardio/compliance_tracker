class VendorAssessment < ApplicationRecord
  belongs_to :vendor
  belongs_to :organization
  belongs_to :assessed_by, class_name: 'User', optional: true

  enum assessment_type: { initial: 0, periodic: 1, incident_driven: 2 }, _prefix: true
  enum status: { pending: 0, in_progress: 1, completed: 2 }, _prefix: true

  validates :assessment_type, presence: true

  scope :recent, -> { order(assessment_date: :desc) }

  def overdue_for_review?
    next_review_date.present? && next_review_date < Date.current
  end
end
