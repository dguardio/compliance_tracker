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

  def prompt
    return nil unless columns.is_a?(Array) && columns.first
    columns.first['prompt']
  end

  def column_type
    return 'text' unless columns.is_a?(Array) && columns.first
    columns.first['column_type'] || 'text'
  end
end
