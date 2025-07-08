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

    # Determine resource type and resource from record if not provided
    resource_type ||= record.class.name if record
    resource ||= record

    # Check if user has permission for this action on this resource type/resource
    Permission.user_has_permission?(user, action.to_s, resource_type, resource)
  end

  # Standard Pundit methods that delegate to our dynamic permission system
  def index?
    can?(:read, record.class.name) if record
  end

  def show?
    can?(:read, record.class.name, record)
  end

  def create?
    can?(:create, record.class.name, record)
  end

  def new?
    create?
  end

  def update?
    can?(:update, record.class.name, record)
  end

  def edit?
    update?
  end

  def destroy?
    can?(:destroy, record.class.name, record)
  end

  def manage?
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
