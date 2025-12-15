class DepartmentsController < ApplicationController
  before_action :set_organization
  before_action :set_department, only: %i[show edit update destroy]
  before_action :authorize_department

  def index
    @departments = @organization.departments.order(:name)
  end

  def show
    @teams = @department.teams.includes(:units)
  end

  def new
    @department = @organization.departments.build
  end

  def create
    @department = @organization.departments.build(department_params)

    if @department.save
      redirect_to organization_departments_path(@organization), notice: 'Department was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @department.update(department_params)
      redirect_to organization_departments_path(@organization), notice: 'Department was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @department.destroy
    redirect_to organization_departments_path(@organization), notice: 'Department was successfully deleted.'
  end

  private

  def set_organization
    @organization = current_organization
  end

  def set_department
    @department = @organization.departments.find(params[:id])
  end

  def department_params
    params.require(:department).permit(:name, :description, :manager_id, settings: {})
  end

  def authorize_department
    case action_name
    when 'index'
      authorize Department.new(organization: @organization), :index?
    when 'show'
      authorize @department, :show?
    when 'new', 'create'
      authorize Department.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @department, :update?
    when 'destroy'
      authorize @department, :destroy?
    end
  end
end
