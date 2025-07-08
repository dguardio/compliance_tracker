class RolesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_role, only: %i[show edit update destroy assign_user remove_user]

  def index
    authorize Role, :index?
    
    # Get roles that are scoped to this organization or its resources
    @roles = Role.where(
      '(resource_type = ? AND resource_id = ?) OR ' \
      '(resource_type = ? AND resource_id IN (?)) OR ' \
      '(resource_type = ? AND resource_id IN (?)) OR ' \
      '(resource_type = ? AND resource_id IN (?))',
      'Organization', current_user.organization.id,
      'Department', current_user.organization.departments.pluck(:id),
      'Team', current_user.organization.teams.pluck(:id),
      'Unit', current_user.organization.units.pluck(:id)
    ).includes(:users, :resource)

    # Filtering
    @roles = @roles.where(name: params[:name]) if params[:name].present?
    @roles = @roles.where(resource_type: params[:resource_type]) if params[:resource_type].present?

    # Search
    @roles = @roles.where('name ILIKE ?', "%#{params[:search]}%") if params[:search].present?

    @roles = @roles.order(:name).page(params[:page]).per(20)

    # For filters
    @resource_types = Role.distinct.pluck(:resource_type).compact.sort
  end

  def show
    authorize @role, :show?
    @users_with_role = @role.users.includes(:department, :team, :unit)
    @permissions_for_role = current_user.organization.permissions.for_role(@role)
  end

  def new
    authorize Role, :create?
    @role = Role.new
    @resource_types = %w[Organization Department Team Unit]
    @organizations = [current_user.organization]
    @departments = current_user.organization.departments
    @teams = current_user.organization.teams
    @units = current_user.organization.units
  end

  def create
    authorize Role, :create?
    @role = Role.new(role_params)
    
    # Set the resource based on resource_type and resource_id
    if role_params[:resource_type].present? && role_params[:resource_id].present?
      resource_class = role_params[:resource_type].constantize
      @role.resource = resource_class.find(role_params[:resource_id])
    elsif role_params[:resource_type].present?
      # Global role for this resource type (no specific resource)
      @role.resource_type = role_params[:resource_type]
      @role.resource_id = nil
    end

    if @role.save
      redirect_to organization_role_path(current_user.organization, @role), notice: 'Role was successfully created.'
    else
      @resource_types = %w[Organization Department Team Unit]
      @organizations = [current_user.organization]
      @departments = current_user.organization.departments
      @teams = current_user.organization.teams
      @units = current_user.organization.units
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @role, :update?
    @resource_types = %w[Organization Department Team Unit]
    @organizations = [current_user.organization]
    @departments = current_user.organization.departments
    @teams = current_user.organization.teams
    @units = current_user.organization.units
  end

  def update
    authorize @role, :update?
    if @role.update(role_params)
      redirect_to organization_role_path(current_user.organization, @role), notice: 'Role was successfully updated.'
    else
      @resource_types = %w[Organization Department Team Unit]
      @organizations = [current_user.organization]
      @departments = current_user.organization.departments
      @teams = current_user.organization.teams
      @units = current_user.organization.units
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @role, :destroy?
    @role.destroy
    redirect_to organization_roles_path(current_user.organization), notice: 'Role was successfully deleted.'
  end

  def assign_user
    authorize @role, :update?
    user = current_user.organization.users.find(params[:user_id])
    user.add_role(@role.name, @role.resource)
    
    redirect_to organization_role_path(current_user.organization, @role), notice: "User #{user.full_name} was successfully assigned to this role."
  end

  def remove_user
    authorize @role, :update?
    user = current_user.organization.users.find(params[:user_id])
    user.remove_role(@role.name, @role.resource)
    
    redirect_to organization_role_path(current_user.organization, @role), notice: "User #{user.full_name} was successfully removed from this role."
  end

  # AJAX endpoint for dynamic form updates
  def get_resources
    authorize Role, :create?
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
    end

    render json: resources
  end

  private

  def set_role
    # Find role that belongs to this organization or its resources
    @role = Role.where(
      '(resource_type = ? AND resource_id = ?) OR ' \
      '(resource_type = ? AND resource_id IN (?)) OR ' \
      '(resource_type = ? AND resource_id IN (?)) OR ' \
      '(resource_type = ? AND resource_id IN (?))',
      'Organization', current_user.organization.id,
      'Department', current_user.organization.departments.pluck(:id),
      'Team', current_user.organization.teams.pluck(:id),
      'Unit', current_user.organization.units.pluck(:id)
    ).find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, :resource_type, :resource_id)
  end
end
