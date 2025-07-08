class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Multi-tenancy configuration
  set_current_tenant_through_filter
  before_action :set_current_tenant

  # Set the default policy class to our ApplicationPolicy
  def policy_scope(scope)
    super(scope)
  end

  def authorize(record, query = nil)
    super(record, query)
  end

  # Handle Pundit authorization errors
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_tenant
    # First try to get organization from URL params (for nested routes)
    if params[:organization_id].present?
      organization = Organization.find_by(id: params[:organization_id])
      ActsAsTenant.current_tenant = organization if organization
    elsif current_user&.organization
      # Fall back to current user's organization
      ActsAsTenant.current_tenant = current_user.organization
    end
  end

  def user_not_authorized
    flash[:alert] = 'You are not authorized to perform this action.'
    redirect_back(fallback_location: root_path)
  end

  # Helper method to check permissions in controllers
  def can?(action, resource_type, resource = nil)
    policy = ApplicationPolicy.new(current_user, resource)
    policy.can?(action, resource_type, resource)
  end

  # Helper method to check if user can manage organization
  def can_manage_organization?(organization = nil)
    policy = ApplicationPolicy.new(current_user, nil)
    policy.can_manage_organization?(organization)
  end

  # Helper method to check if user can manage users
  def can_manage_users?
    policy = ApplicationPolicy.new(current_user, nil)
    policy.can_manage_users?
  end

  # Helper method to check if user can manage roles
  def can_manage_roles?
    policy = ApplicationPolicy.new(current_user, nil)
    policy.can_manage_roles?
  end

  # Helper method to check if user can manage permissions
  def can_manage_permissions?
    policy = ApplicationPolicy.new(current_user, nil)
    policy.can_manage_permissions?
  end
end
