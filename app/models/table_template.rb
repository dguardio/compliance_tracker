class TableTemplate < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  scope :system, -> { where(user_id: nil, organization_id: nil) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_organization, ->(org) { where(organization: org) }

  def self.available_for(user)
    where(user: user)
      .or(where(organization: user.organization))
      .or(where(user_id: nil, organization_id: nil))
  end
end
