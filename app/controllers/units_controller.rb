class UnitsController < ApplicationController
  before_action :set_organization
  before_action :set_unit, only: [:show, :edit, :update, :destroy]
  before_action :authorize_unit

  def index
    @units = @organization.units.includes(:team, :department, :users).page(params[:page]).per(20)
  end

  def show
    @users = @unit.users.includes(:roles)
  end

  def new
    @unit = @organization.units.build
  end

  def create
    @unit = @organization.units.build(unit_params)

    if @unit.save
      redirect_to organization_unit_path(@organization, @unit), 
                    notice: 'Unit was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @unit.update(unit_params)
      redirect_to organization_unit_path(@organization, @unit), 
                    notice: 'Unit was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @unit.destroy
    redirect_to organization_units_path(@organization), 
                notice: 'Unit was successfully deleted.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_unit
    @unit = @organization.units.find(params[:id])
  end

  def unit_params
    params.require(:unit).permit(:name, :slug, :team_id, :status, :settings)
  end

  def authorize_unit
    case action_name
    when 'index'
      authorize Unit.new(organization: @organization), :index?
    when 'show'
      authorize @unit, :show?
    when 'new', 'create'
      authorize Unit.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @unit, :update?
    when 'destroy'
      authorize @unit, :destroy?
    end
  end
end 