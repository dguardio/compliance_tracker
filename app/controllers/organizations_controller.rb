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

  # Switch organization logic is deprecated; use current_user.organization only

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(
      :name, :slug, :domain, :status,
      settings: [
        :auto_assignment_enabled,
        compliance_industries: [],
        compliance_jurisdictions: [],
        compliance_keywords: [],
        exclusion_terms: []
      ]
    )
  end
end
