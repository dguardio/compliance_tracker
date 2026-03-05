class StandardRequirement < ApplicationRecord
  belongs_to :regulation
  has_many :compliance_requirements, dependent: :nullify

  validates :name, presence: true
  validates :description, presence: true

  has_neighbors :embedding

  scope :related_to, ->(vector) { nearest_neighbors(:embedding, vector, distance: "cosine") }

  private
end
