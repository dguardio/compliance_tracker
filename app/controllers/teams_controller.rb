class TeamsController < ApplicationController
  before_action :set_organization
  before_action :set_team, only: %i[show edit update destroy]
  before_action :authorize_team

  def index
    @teams = @organization.teams.includes(:department, :units).page(params[:page]).per(20)
  end

  def show
    @units = @team.units.includes(:users)
  end

  def new
    @team = @organization.teams.build
  end

  def create
    @team = @organization.teams.build(team_params)

    if @team.save
      redirect_to organization_team_path(@organization, @team),
                  notice: 'Team was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @team.update(team_params)
      redirect_to organization_team_path(@organization, @team),
                  notice: 'Team was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team.destroy
    redirect_to organization_teams_path(@organization),
                notice: 'Team was successfully deleted.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_team
    @team = @organization.teams.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :slug, :department_id, :status, :settings)
  end

  def authorize_team
    case action_name
    when 'index'
      authorize Team.new(organization: @organization), :index?
    when 'show'
      authorize @team, :show?
    when 'new', 'create'
      authorize Team.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @team, :update?
    when 'destroy'
      authorize @team, :destroy?
    end
  end
end
