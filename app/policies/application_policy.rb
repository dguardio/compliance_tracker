# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # Master method to check any permission dynamically
  def can?(action, resource_type = nil, resource = nil)
    return false unless user&.organization

    # Super admins have full access to everything
    return true if user.super_admin?

    # Organization admins have full access within their organization
    if user.organization_admin? && resource_type != 'Organization'
      # For organization-scoped resources, org admins have full access
      return true
    end

    # Determine resource type and resource from record if not provided
    resource_type ||= record.class.name if record
    resource ||= record

    # Debug logging (remove in production)
    # puts "DEBUG: can?(#{action}, #{resource_type}, #{resource&.id}) - calling Permission.user_has_permission?"

    # Check if user has permission for this action on this resource type/resource
    Permission.user_has_permission?(user, action.to_s, resource_type, resource)

    # Debug logging (remove in production)
    # puts "DEBUG: Permission.user_has_permission? returned: #{result}"
  end

  # Standard Pundit methods that delegate to our dynamic permission system
  def index?
    # For index actions, we check permissions on the resource type, not a specific record
    resource_type = record.class.name if record
    can?(:read, resource_type) if resource_type
  end

  def show?
    # First check for global read permission
    return true if can?(:read, record.class.name)

    # Then check for resource-specific permission
    can?(:read, record.class.name, record)
  end

  def create?
    # First check for global create permission
    return true if can?(:create, record.class.name)

    # Then check for resource-specific permission
    can?(:create, record.class.name, record)
  end

  def new?
    create?
  end

  def update?
    # First check for global update permission
    return true if can?(:update, record.class.name)

    # Then check for resource-specific permission
    can?(:update, record.class.name, record)
  end

  def edit?
    update?
  end

  def destroy?
    # First check for global destroy permission
    return true if can?(:destroy, record.class.name)

    # Then check for resource-specific permission
    can?(:destroy, record.class.name, record)
  end

  def manage?
    # First check for global manage permission
    return true if can?(:manage, record.class.name)

    # Then check for resource-specific permission
    can?(:manage, record.class.name, record)
  end

  def assign?
    can?(:assign, record.class.name, record)
  end

  def delegate?
    can?(:delegate, record.class.name, record)
  end

  # Scope class for index actions
  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return @scope.none unless @user&.organization

      # Get permissions for this resource type
      permissions = @user.organization.permissions.for_user(@user)
                         .for_action('read')
                         .for_resource_type(@scope.name)

      # If user has global read permission for this resource type, return all
      if permissions.any? { |p| p.global? && p.can_perform?(@user) }
        @scope.all
      else
        # Filter based on specific resource permissions
        allowed_resource_ids = []

        permissions.each do |permission|
          if permission.resource_specific? && permission.can_perform?(@user, permission.resource)
            allowed_resource_ids << permission.resource_id
          end
        end

        if allowed_resource_ids.any?
          @scope.where(id: allowed_resource_ids)
        else
          @scope.none
        end
      end
    end

    private

    attr_reader :user, :scope
  end

  # Helper methods for common permission checks
  def can_manage_organization?(organization = nil)
    org = organization || user.organization
    can?(:manage, 'Organization', org)
  end

  def can_manage_users?
    can?(:manage, 'User')
  end

  def can_manage_roles?
    can?(:manage, 'Role')
  end

  def can_manage_permissions?
    can?(:manage, 'Permission')
  end

  def can_manage_departments?
    can?(:manage, 'Department')
  end

  def can_manage_teams?
    can?(:manage, 'Team')
  end

  def can_manage_units?
    can?(:manage, 'Unit')
  end

  def can_read_users?
    can?(:read, 'User')
  end

  def can_read_roles?
    can?(:read, 'Role')
  end

  def can_read_permissions?
    can?(:read, 'Permission')
  end

  def can_read_departments?
    can?(:read, 'Department')
  end

  def can_read_teams?
    can?(:read, 'Team')
  end

  def can_read_units?
    can?(:read, 'Unit')
  end

  # Method to check if user can access a specific resource
  def can_access_resource?(resource)
    return false unless resource

    can?(:read, resource.class.name, resource)
  end

  # Method to check if user can manage a specific resource
  def can_manage_resource?(resource)
    return false unless resource

    can?(:manage, resource.class.name, resource)
  end

  # Method to check if user can perform a specific action on a resource
  def can_perform_action?(action, resource_type, resource = nil)
    can?(action, resource_type, resource)
  end

  # Method to check if user has any permission for a resource type
  def has_any_permission_for?(resource_type)
    return false unless user&.organization

    permissions = user.organization.permissions.for_user(user).for_resource_type(resource_type)
    permissions.any? { |p| p.can_perform?(user) }
  end

  # Method to get all actions user can perform on a resource type
  def allowed_actions_for(resource_type, resource = nil)
    return [] unless user&.organization

    permissions = user.organization.permissions.for_user(user).for_resource_type(resource_type)

    permissions = if resource
                    permissions.select { |p| p.can_perform?(user, resource) }
                  else
                    permissions.select { |p| p.can_perform?(user) }
                  end

    permissions.map(&:action).uniq
  end
end
