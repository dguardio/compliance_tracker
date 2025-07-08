class OrganizationsController < ApplicationController
  # Skip tenant scoping for organization management (super admin needs to see all)
  skip_before_action :set_current_tenant, only: [:index, :show, :new, :create]
  
  before_action :authenticate_user!
  before_action :set_organization, only: %i[show edit update destroy]

  def index
    @organizations = if current_user.super_admin?
                       Organization.all.order(:name)
                     else
                       Organization.where(id: current_user.organization_id)
                     end
  end

  def show
    authorize @organization, :show?
    @departments = @organization.departments.includes(:teams, :units)
    @users = @organization.users.includes(:roles, :department, :team, :unit)
    @stats = {
      departments: @organization.department_count,
      teams: @organization.team_count,
      units: @organization.unit_count,
      users: @organization.user_count
    }
  end

  def new
    @organization = Organization.new
    authorize @organization, :create?
  end

  def create
    @organization = Organization.new(organization_params)
    authorize @organization, :create?

    if @organization.save
      # If user is creating their first organization, assign them as admin
      if current_user.organization.nil?
        current_user.update!(organization: @organization)
        current_user.add_role(:organization_admin, @organization)
      end

      redirect_to @organization, notice: 'Organization was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @organization, :update?
  end

  def update
    authorize @organization, :update?
    if @organization.update(organization_params)
      redirect_to @organization, notice: 'Organization was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @organization, :destroy?
    if @organization.users.count > 0
      redirect_to @organization, alert: 'Cannot delete organization with existing users.'
    else
      @organization.destroy
      redirect_to organizations_path, notice: 'Organization was successfully deleted.'
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    # Convert comma-separated strings to arrays for settings
    params_hash = params.require(:organization).permit(
      :name, :slug, :domain, :status,
      :industry, :jurisdiction, :compliance_keywords, :exclusion_terms
    ).to_h

    # Process settings
    settings = {}
    settings[:industry] = params_hash[:industry] if params_hash[:industry].present?
    settings[:jurisdiction] = params_hash[:jurisdiction] if params_hash[:jurisdiction].present?
    settings[:compliance_keywords] = params_hash[:compliance_keywords]&.split(',')&.map(&:strip)&.reject(&:blank?) || []
    settings[:exclusion_terms] = params_hash[:exclusion_terms]&.split(',')&.map(&:strip)&.reject(&:blank?) || []
    settings[:notification_preferences] = {}
    settings[:ai_settings] = {}
    settings[:branding] = {}

    # Remove settings keys from main params and add settings hash
    params_hash.except(:industry, :jurisdiction, :compliance_keywords, :exclusion_terms).merge(settings: settings)
  end
end
