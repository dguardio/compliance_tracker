class ComplianceFrameworksController < ApplicationController
  before_action :set_organization
  before_action :set_compliance_framework, only: %i[show edit update destroy]
  before_action :authorize_compliance_framework

  def index
    @q = @organization.compliance_frameworks.includes(:compliance_requirements).ransack(params[:q])
    @compliance_frameworks = @q.result(distinct: true).page(params[:page]).per(20)
  end

  def show
    @compliance_requirements = @compliance_framework.compliance_requirements.includes(:compliance_controls)
  end

  def new
    @compliance_framework = @organization.compliance_frameworks.build
  end

  def create
    @compliance_framework = @organization.compliance_frameworks.build(compliance_framework_params)

    if @compliance_framework.save
      redirect_to organization_compliance_framework_path(@organization, @compliance_framework),
                  notice: 'Compliance framework was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @compliance_framework.update(compliance_framework_params)
      redirect_to organization_compliance_framework_path(@organization, @compliance_framework),
                  notice: 'Compliance framework was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @compliance_framework.destroy
    redirect_to organization_compliance_frameworks_path(@organization),
                notice: 'Compliance framework was successfully deleted.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_compliance_framework
    @compliance_framework = @organization.compliance_frameworks.find(params[:id])
  end

  def compliance_framework_params
    params.require(:compliance_framework).permit(:name, :slug, :description, :version, :status, :settings)
  end

  def authorize_compliance_framework
    case action_name
    when 'index'
      authorize ComplianceFramework.new(organization: @organization), :index?
    when 'show'
      authorize @compliance_framework, :show?
    when 'new', 'create'
      authorize ComplianceFramework.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @compliance_framework, :update?
    when 'destroy'
      authorize @compliance_framework, :destroy?
    end
  end
end
