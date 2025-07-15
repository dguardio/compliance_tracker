class Role < ApplicationRecord
  has_and_belongs_to_many :users, join_table: :users_roles

  belongs_to :resource,
             polymorphic: true,
             optional: true

  belongs_to :organization, optional: true # Allow global roles (organization_id = nil)

  # Configure Rolify resource types
  rolify

  # Validations
  validates :name, presence: true, uniqueness: { scope: %i[resource_type resource_id organization_id] }
  validates :resource_type,
            inclusion: { in: %w[Organization Department Team Unit User] },
            allow_nil: true

  # Scopes
  scope :global_roles, -> { where(organization_id: nil) }
  scope :organization_specific_roles, -> { where.not(organization_id: nil) }
  scope :for_organization, ->(org) { where(organization: org) }
  scope :available_for_organization, ->(org) { where("organization_id IS NULL OR organization_id = ?", org.id) }
  scope :organization_roles, -> { where(resource_type: 'Organization') }
  scope :department_roles, -> { where(resource_type: 'Department') }
  scope :team_roles, -> { where(resource_type: 'Team') }
  scope :unit_roles, -> { where(resource_type: 'Unit') }
  scope :by_name, -> { order(:name) }

  # Instance methods
  def display_name
    if resource
      "#{name.titleize} (#{resource.display_name})"
    elsif global?
      "#{name.titleize} (Global)"
    else
      "#{name.titleize} (#{organization&.name})"
    end
  end

  def global?
    organization_id.nil?
  end

  def organization_specific?
    organization_id.present?
  end

  def available_for_organization?(org)
    global? || organization_id == org.id
  end

  def can_be_edited_by?(user)
    return true if user.super_admin?
    return true if user.organization_admin? && organization_id == user.organization_id
    false
  end

  def can_be_deleted_by?(user)
    return false if global? && !user.super_admin?
    return true if user.super_admin?
    return true if user.organization_admin? && organization_id == user.organization_id
    false
  end

  def user_count
    users.count
  end

  def description
    case name
    when 'super_admin'
      'Full system access across all organizations'
    when 'admin'
      'Administrative access within organization'
    when 'organization_admin'
      'Administrative access for specific organization'
    when 'department_admin'
      'Administrative access for specific department'
    when 'team_lead'
      'Leadership role for specific team'
    when 'unit_manager'
      'Management role for specific unit'
    when 'compliance_officer'
      'Compliance management and oversight'
    when 'user'
      'Standard user access'
    else
      'Custom role'
    end
  end

  scopify
end
