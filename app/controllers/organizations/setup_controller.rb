class Organizations::SetupController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :ensure_admin

  layout 'organization_setup'

  def index
    # Start of the wizard
    redirect_to step_path(:departments)
  end

  def show
    @step = params[:id].to_sym
    render_step
  end

  def update
    @step = params[:id].to_sym
    if process_step
      next_step = get_next_step(@step)
      if next_step
        redirect_to step_path(next_step)
      else
        Ai::OrganizationResearchAgent.perform_later(@organization)
        redirect_to organization_path(@organization), notice: 'Organization setup completed! Researching your compliance profile...'
      end
    else
      render_step
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def ensure_admin
    unless current_user.can_manage_organization?(@organization)
      redirect_to root_path, alert: 'Not authorized.'
    end
  end

  def step_path(step)
    organization_setup_path(@organization, step)
  end

  def render_step
    case @step
    when :departments
      @department = @organization.departments.new
      @departments = @organization.departments
    when :teams
      @team = Team.new
      @teams = @organization.teams.includes(:department)
    when :units
      @unit = Unit.new
      @units = @organization.units.includes(:team)
    when :users
      @user = User.new
      @users = @organization.users
    else
      redirect_to organization_path(@organization)
    end
    render @step
  end

  def process_step
    case @step
    when :departments
      if params[:department].present?
        @department = @organization.departments.build(department_params)
        @department.save
      end
      true # Always proceed, user can skip adding
    when :teams
      if params[:team].present?
        @team = Team.new(team_params)
        @team.save
      end
      true
    when :units
      if params[:unit].present?
        @unit = Unit.new(unit_params)
        @unit.save
      end
      true
    when :users
      # User invitation logic would go here, maybe just a redirect to registration for now
      true
    else
      false
    end
  end

  def get_next_step(current)
    steps = [:departments, :teams, :units, :users]
    idx = steps.index(current)
    return nil unless idx
    steps[idx + 1]
  end

  def department_params
    params.require(:department).permit(:name, :description)
  end

  def team_params
    params.require(:team).permit(:name, :department_id, :description)
  end

  def unit_params
    params.require(:unit).permit(:name, :team_id, :description)
  end
end
