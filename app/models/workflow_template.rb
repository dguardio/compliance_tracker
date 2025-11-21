# frozen_string_literal: true

class WorkflowTemplate < ApplicationRecord
  belongs_to :organization
  has_many :workflow_steps, dependent: :destroy
  has_many :regulation_reviews, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :organization_id }
  validates :is_default, uniqueness: { scope: :organization_id }, if: :is_default?

  scope :default, -> { where(is_default: true) }
end
