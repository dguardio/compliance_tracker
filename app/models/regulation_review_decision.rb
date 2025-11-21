# frozen_string_literal: true

class RegulationReviewDecision < ApplicationRecord
  belongs_to :regulation_review
  belongs_to :workflow_step
  belongs_to :user

  validates :decision, presence: true
end
