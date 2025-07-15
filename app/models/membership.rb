class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  # Optionally, you can add validations for role and status
  validates :user_id, presence: true
  validates :organization_id, presence: true
end
