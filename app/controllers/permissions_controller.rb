class PermissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_permission, only: %i[show edit update destroy]

  # Specify the policy class to use
  def policy_class
    PermissionPolicy
  end

  def index
    authorize Permission, :index?
    @permissions = current_user.organization.permissions.includes(:grantee, :resource)

    # Filtering
    @permissions = @permissions.for_grantee_type(params[:grantee_type]) if params[:grantee_type].present?
    @permissions = @permissions.for_action(params[:permission_action]) if params[:permission_action].present?
    @permissions = @permissions.for_resource_type(params[:resource_type]) if params[:resource_type].present?

    # Search
    @permissions = @permissions.where('name ILIKE ?', "%#{params[:search]}%") if params[:search].present?

    # Apply pagination
    @permissions = @permissions.order(:name).page(params[:page]).per(20)

    # For filters
    @grantee_types = %w[User Role]
    @actions = Permission.distinct.pluck(:action).sort
    @resource_types = Permission.distinct.pluck(:resource_type).compact.sort
  end

  def show
    authorize @permission, :show?
    @grantee = @permission.grantee
    @resource = @permission.resource
  end

  def new
    authorize Permission, :create?
    @permission = Permission.new
    @resource_types = %w[Organization Department Team Unit User]
    @actions = %w[create read update destroy manage assign delegate]
    @grantee_types = %w[User Role]
    @organizations = [current_user.organization]
    @departments = current_user.organization.departments
    @teams = current_user.organization.teams
    @units = current_user.organization.units
    @users = current_user.organization.users
    @roles = current_user.organization.roles
  end

  def create
    authorize Permission, :create?
    @permission = Permission.new(permission_params)
    @permission.organization = current_user.organization

    if @permission.save
      redirect_to organization_permission_path(current_user.organization, @permission), notice: 'Permission was successfully created.'
    else
      @resource_types = %w[Organization Department Team Unit User]
      @actions = %w[create read update destroy manage assign delegate]
      @grantee_types = %w[User Role]
      @organizations = [current_user.organization]
      @departments = current_user.organization.departments
      @teams = current_user.organization.teams
      @units = current_user.organization.units
      @users = current_user.organization.users
      @roles = current_user.organization.roles
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @permission, :update?
    @resource_types = %w[Organization Department Team Unit User]
    @actions = %w[create read update destroy manage assign delegate]
    @grantee_types = %w[User Role]
    @organizations = [current_user.organization]
    @departments = current_user.organization.departments
    @teams = current_user.organization.teams
    @units = current_user.organization.units
    @users = current_user.organization.users
    @roles = current_user.organization.roles
  end

  def update
    authorize @permission, :update?
    if @permission.update(permission_params)
      redirect_to organization_permission_path(current_user.organization, @permission), notice: 'Permission was successfully updated.'
    else
      @resource_types = %w[Organization Department Team Unit User]
      @actions = %w[create read update destroy manage assign delegate]
      @grantee_types = %w[User Role]
      @organizations = [current_user.organization]
      @departments = current_user.organization.departments
      @teams = current_user.organization.teams
      @units = current_user.organization.units
      @users = current_user.organization.users
      @roles = current_user.organization.roles
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @permission, :destroy?
    @permission.destroy
    redirect_to organization_permissions_path(current_user.organization), notice: 'Permission was successfully deleted.'
  end

  # AJAX endpoints for dynamic form updates
  def get_resources
    authorize Permission, :create?
    resource_type = params[:resource_type]
    resources = []

    case resource_type
    when 'Organization'
      resources = [{ id: current_user.organization.id, name: current_user.organization.name }]
    when 'Department'
      resources = current_user.organization.departments.map { |d| { id: d.id, name: d.name } }
    when 'Team'
      resources = current_user.organization.teams.map { |t| { id: t.id, name: t.name } }
    when 'Unit'
      resources = current_user.organization.units.map { |u| { id: u.id, name: u.name } }
    when 'User'
      resources = current_user.organization.users.map { |u| { id: u.id, name: u.full_name } }
    end

    render json: resources
  end

  def get_grantee_options
    authorize Permission, :create?
    grantee_type = params[:grantee_type]
    options = []

    case grantee_type
    when 'User'
      options = current_user.organization.users.map { |u| { id: u.id, name: u.full_name } }
    when 'Role'
      options = current_user.organization.roles.map { |r| { id: r.id, name: r.name } }
    end

    render json: options
  end

  private

  def set_permission
    @permission = current_user.organization.permissions.find(params[:id])
  end

  def permission_params
    params.require(:permission).permit(:name, :action, :resource_type, :resource_id, :grantee_type, :grantee_id, conditions: {})
  end
end
