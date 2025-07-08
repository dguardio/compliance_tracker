class User < ApplicationRecord
  rolify
  acts_as_tenant(:organization)
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Multi-tenancy associations
  belongs_to :organization, optional: true
  belongs_to :department, optional: true
  belongs_to :team, optional: true
  belongs_to :unit, optional: true

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :organization, presence: true, if: :requires_organization?

  # JSONB Settings
  jsonb_accessor :settings,
                 first_name: :string,
                 last_name: :string,
                 job_title: :string,
                 phone: :string,
                 timezone: :string,
                 compliance_preferences: :json,
                 notification_settings: :json,
                 ui_preferences: :json,
                 custom_fields: :json

  # Scopes
  scope :active, -> { where(organization: Organization.active) }
  scope :for_organization, ->(org) { where(organization: org) }
  scope :for_department, ->(dept) { where(department: dept) }
  scope :for_team, ->(team) { where(team: team) }
  scope :for_unit, ->(unit) { where(unit: unit) }
  scope :by_name, -> { order(:first_name, :last_name) }

  # Instance methods
  def full_name
    [first_name, last_name].compact.join(' ').presence || email
  end

  def display_name
    full_name
  end

  def admin?
    has_role?(:admin)
  end

  def super_admin?
    has_role?(:super_admin)
  end

  def organization_admin?
    has_role?(:organization_admin, organization)
  end

  def department_admin?
    has_role?(:department_admin, department)
  end

  def team_lead?
    has_role?(:team_lead, team)
  end

  def unit_manager?
    has_role?(:unit_manager, unit)
  end

  def compliance_officer?
    has_role?(:compliance_officer)
  end

  def can_manage_organization?(org = nil)
    target_org = org || organization
    return false unless target_org

    super_admin? ||
      (organization_admin? && organization == target_org) ||
      (admin? && organization == target_org)
  end

  def can_manage_department?(dept = nil)
    target_dept = dept || department
    return false unless target_dept

    super_admin? ||
      can_manage_organization?(target_dept.organization) ||
      (department_admin? && department == target_dept)
  end

  def can_manage_team?(team_obj = nil)
    target_team = team_obj || team
    return false unless target_team

    super_admin? ||
      can_manage_department?(target_team.department) ||
      (team_lead? && team == target_team)
  end

  def can_manage_unit?(unit_obj = nil)
    target_unit = unit_obj || unit
    return false unless target_unit

    super_admin? ||
      can_manage_team?(target_unit.team) ||
      (unit_manager? && unit == target_unit)
  end

  def can_manage_user?(target_user)
    return false unless target_user

    super_admin? ||
      can_manage_organization?(target_user.organization) ||
      can_manage_department?(target_user.department) ||
      can_manage_team?(target_user.team) ||
      can_manage_unit?(target_user.unit)
  end

  def hierarchical_path
    [organization&.name, department&.name, team&.name, unit&.name].compact.join(' > ')
  end

  def active?
    organization&.active?
  end

  # Permission checking methods
  def has_permission?(action, resource_type, resource = nil)
    return true if super_admin?

    # Check direct permissions
    direct_permissions = organization.permissions.for_user(self).for_action(action).for_resource_type(resource_type)
    direct_permissions.each do |permission|
      return true if permission.can_perform?(self, resource)
    end

    # Check role-based permissions
    roles.each do |role|
      role_permissions = organization.permissions.for_role(role).for_action(action).for_resource_type(resource_type)
      role_permissions.each do |permission|
        return true if permission.can_perform?(self, resource)
      end
    end

    false
  end

  def can_perform_action?(action, resource)
    return true if super_admin?

    resource_type = resource.class.name
    has_permission?(action, resource_type, resource)
  end

  def permissions_for_resource(resource_type, resource = nil)
    return [] unless organization

    permissions = []

    # Direct permissions
    permissions += organization.permissions.for_user(self).for_resource_type(resource_type)

    # Role-based permissions
    roles.each do |role|
      permissions += organization.permissions.for_role(role).for_resource_type(resource_type)
    end

    # Filter by resource if specified
    permissions.select! { |p| p.can_perform?(self, resource) } if resource

    permissions.uniq
  end

  # Permission checking methods for Pundit integration
  def can_manage_organization?(organization = nil)
    org = organization || self.organization
    return false unless org
    
    # Super admins can manage any organization
    return true if super_admin?
    
    # Check if user has organization_admin role for this organization
    has_role?(:organization_admin, org) || has_role?(:admin, org)
  end

  private

  def requires_organization?
    # Only require organization for non-super-admin users
    !has_role?(:super_admin)
  end
end
