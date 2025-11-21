# frozen_string_literal: true

class Feedback < ApplicationRecord
  belongs_to :user
  belongs_to :feedbackable, polymorphic: true

  validates :content, presence: true
  validates :status, presence: true, inclusion: { in: %w[open resolved] }

  enum status: { open: 'open', resolved: 'resolved' }

  # Scopes
  scope :open_feedback, -> { where(status: 'open') }
  scope :resolved_feedback, -> { where(status: 'resolved') }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_feedbackable, ->(feedbackable) { where(feedbackable: feedbackable) }
end
