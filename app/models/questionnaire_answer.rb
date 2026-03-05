class QuestionnaireAnswer < ApplicationRecord
  belongs_to :questionnaire_upload
  belongs_to :source_policy, class_name: 'Policy', optional: true

  enum status: { pending: 0, approved: 1, edited: 2 }, _prefix: true

  validates :question_text, presence: true

  scope :pending_review, -> { where(status: :pending) }
  scope :approved, -> { where(status: :approved) }

  def approve!(answer = nil)
    update!(
      approved_answer: answer || ai_answer,
      status: :approved
    )
  end
end
