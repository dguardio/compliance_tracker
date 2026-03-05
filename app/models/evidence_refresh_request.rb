class EvidenceRefreshRequest < ApplicationRecord
  belongs_to :document
  belongs_to :requester, class_name: 'User'
  belongs_to :fulfilled_by, class_name: 'User', optional: true

  enum status: { pending: 0, fulfilled: 1, expired: 2, cancelled: 3 }

  validates :reason, presence: true

  scope :open, -> { where(status: :pending) }
  scope :recent, -> { order(created_at: :desc) }

  def fulfill!(user)
    update!(status: :fulfilled, fulfilled_at: Time.current, fulfilled_by: user)
  end
end
