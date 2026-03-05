class QuestionnaireUpload < ApplicationRecord
  belongs_to :organization
  belongs_to :uploaded_by, class_name: 'User', optional: true
  has_many :questionnaire_answers, dependent: :destroy
  has_one_attached :file

  enum status: { processing: 0, ready: 1, exported: 2 }, _prefix: true

  validates :filename, presence: true

  scope :recent, -> { order(created_at: :desc) }

  def completion_rate
    return 0 if questionnaire_answers.count.zero?
    approved = questionnaire_answers.where(status: :approved).count
    ((approved.to_f / questionnaire_answers.count) * 100).round(1)
  end

  def pending_count
    questionnaire_answers.where(status: :pending).count
  end
end
