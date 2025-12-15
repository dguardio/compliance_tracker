class OrganizationsController < ApplicationController
  # Skip tenant scoping for organization management (super admin needs to see all)
  skip_before_action :set_current_tenant, only: [:index, :show, :new, :create]
  
  before_action :authenticate_user!
  before_action :set_organization, only: %i[show edit update destroy enrich]
  before_action :prepare_settings_arrays, only: %i[create update]

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

  def enrich
    Ai::OrganizationResearchAgent.perform_later(@organization)
    
    respond_to do |format|
      format.html { redirect_to @organization, notice: "Deep Research initiated. We're building your compliance profile..." }
      format.turbo_stream
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

  def prepare_settings_arrays
    # Check top-level organization params
    org_params = params[:organization]
    return unless org_params

    %i[compliance_industries compliance_jurisdictions compliance_keywords exclusion_terms].each do |key|
      if org_params[key].is_a?(String)
        org_params[key] = org_params[key].split(',').map(&:strip).reject(&:blank?)
      end
    end
  end

  def organization_params
    params.require(:organization).permit(
      :name, :slug, :domain, :status,
      :logo_url, :primary_color, :secondary_color, :accent_color, :text_color, :background_color,
      :auto_assignment_enabled,
      compliance_industries: [],
      compliance_jurisdictions: [],
      compliance_keywords: [],
      exclusion_terms: []
    )
  end
end
