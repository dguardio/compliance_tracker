class Permission < ApplicationRecord
  acts_as_tenant(:organization)

  # Associations
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :grantee, polymorphic: true # Can be either Role or User

  # Validations
  validates :name, presence: true,
                   uniqueness: { scope: %i[organization_id resource_type resource_id action grantee_type grantee_id] }
  validates :action, presence: true, inclusion: { in: %w[create read update destroy manage assign delegate] }
  validates :resource_type, presence: true
  validates :grantee_type, presence: true, inclusion: { in: %w[Role User] }
  validates :grantee_id, presence: true

  # JSONB Settings
  jsonb_accessor :conditions,
                 user_conditions: :json,
                 time_conditions: :json,
                 data_conditions: :json,
                 custom_rules: :json,
                 scope_conditions: :json

  # Scopes
  scope :global, -> { where(resource: nil) }
  scope :for_resource, ->(resource) { where(resource: resource) }
  scope :for_action, ->(action) { where(action: action) }
  scope :for_resource_type, ->(type) { where(resource_type: type) }
  scope :for_grantee, ->(grantee) { where(grantee: grantee) }
  scope :for_user, ->(user) { where(grantee_type: 'User', grantee_id: user.id) }
  scope :for_role, ->(role) { where(grantee_type: 'Role', grantee_id: role.id) }
  scope :for_grantee_type, ->(type) { where(grantee_type: type) }
  scope :by_name, -> { order(:name) }

  # Instance methods
  def display_name
    grantee_name = grantee.respond_to?(:display_name) ? grantee.display_name : grantee.name
    resource_name = resource&.display_name || resource_type

    if resource
      "#{name} (#{action.titleize} #{resource_type} - #{resource_name}) → #{grantee_name}"
    else
      "#{name} (#{action.titleize} #{resource_type}) → #{grantee_name}"
    end
  end

  def global?
    resource.nil?
  end

  def resource_specific?
    resource.present?
  end

  def granted_to_user?
    grantee_type == 'User'
  end

  def granted_to_role?
    grantee_type == 'Role'
  end

  def can_perform?(user, target_resource = nil)
    return false unless user.organization == organization

    # Direct user permission
    return check_conditions(user, target_resource) if granted_to_user? && grantee_id == user.id

    # Role-based permission
    if granted_to_role?
      # Get all roles the user has (Rolify handles the polymorphic associations)
      user.roles.each do |role|
        return check_conditions(user, target_resource) if role.id == grantee_id
      end
    end

    false
  end

  def check_conditions(user, target_resource = nil)
    # Check time conditions
    return false if time_conditions.present? && !check_time_conditions(time_conditions)

    # Check user conditions
    return false if user_conditions.present? && !check_user_conditions(user, user_conditions)

    # Check data conditions
    if data_conditions.present? && target_resource && !check_data_conditions(target_resource, data_conditions)
      return false
    end

    # Check custom rules
    return false if custom_rules.present? && !check_custom_rules(user, target_resource, custom_rules)

    true
  end

  private

  def check_time_conditions(conditions)
    # Example: check if current time is within allowed hours
    return true if conditions.blank?

    current_time = Time.current
    start_time = conditions['start_time']
    end_time = conditions['end_time']

    if start_time && end_time
      start = Time.parse(start_time)
      finish = Time.parse(end_time)
      return current_time.between?(start, finish)
    end

    true
  end

  def check_user_conditions(user, conditions)
    # Example: check user attributes
    return true if conditions.blank?

    return false if conditions['department_id'] && !(user.department_id == conditions['department_id'])

    return false if conditions['team_id'] && !(user.team_id == conditions['team_id'])

    return false if conditions['unit_id'] && !(user.unit_id == conditions['unit_id'])

    true
  end

  def check_data_conditions(resource, conditions)
    # Example: check resource attributes
    return true if conditions.blank?

    return false if conditions['status'] && !(resource.status == conditions['status'])

    if conditions['owner_id'] && !(resource.respond_to?(:user_id) && resource.user_id == conditions['owner_id'])
      return false
    end

    true
  end

  def check_custom_rules(user, target_resource, rules)
    # Custom business logic rules
    return true if rules.blank?

    # Example: only allow access during business hours
    if rules['business_hours_only']
      current_hour = Time.current.hour
      return false unless current_hour.between?(9, 17)
    end

    # Example: require specific user attributes
    return false if rules['require_verified_email'] && !user.email_verified?

    true
  end

  def description
    grantee_type_text = granted_to_user? ? 'User' : 'Role'
    resource_text = resource ? resource.display_name : resource_type.underscore.pluralize

    case action
    when 'create'
      "Can create new #{resource_text} (Granted to #{grantee_type_text})"
    when 'read'
      "Can view #{resource_text} (Granted to #{grantee_type_text})"
    when 'update'
      "Can edit #{resource_text} (Granted to #{grantee_type_text})"
    when 'destroy'
      "Can delete #{resource_text} (Granted to #{grantee_type_text})"
    when 'manage'
      "Can manage all aspects of #{resource_text} (Granted to #{grantee_type_text})"
    when 'assign'
      "Can assign #{resource_text} to others (Granted to #{grantee_type_text})"
    when 'delegate'
      "Can delegate permissions for #{resource_text} (Granted to #{grantee_type_text})"
    else
      "Custom permission for #{resource_text} (Granted to #{grantee_type_text})"
    end
  end

  # Class methods for creating common permissions
  def self.create_standard_permissions(organization, resource_type, resource = nil, grantee = nil)
    permissions = []

    %w[create read update destroy manage].each do |action|
      permission = find_or_create_by(
        organization: organization,
        name: "#{action}_#{resource_type.underscore}",
        resource_type: resource_type,
        resource: resource,
        action: action,
        grantee: grantee
      )
      permissions << permission
    end

    permissions
  end

  # Helper methods for checking permissions
  def self.user_has_permission?(user, action, resource_type, resource = nil)
    return false unless user.organization

    # Check direct user permissions
    user_permissions = for_user(user).for_action(action).for_resource_type(resource_type)
    user_permissions = user_permissions.for_resource(resource) if resource

    return true if user_permissions.any? { |p| p.can_perform?(user, resource) }

    # Check role-based permissions
    # Get all roles the user has (Rolify handles the polymorphic associations)
    user.roles.each do |role|
      role_permissions = for_role(role).for_action(action).for_resource_type(resource_type)
      role_permissions = role_permissions.for_resource(resource) if resource

      return true if role_permissions.any? { |p| p.can_perform?(user, resource) }
    end

    false
  end
end
