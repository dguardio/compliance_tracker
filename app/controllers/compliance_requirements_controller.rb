class ComplianceRequirementsController < ApplicationController
  before_action -> { require_feature!(:compliance_management) }
  before_action :set_organization
  before_action :set_compliance_framework
  before_action :set_compliance_requirement, only: %i[show edit update destroy]
  before_action :authorize_compliance_requirement

  def index
    @q = @compliance_framework.compliance_requirements.includes(:compliance_controls).ransack(params[:q])
    @compliance_requirements = @q.result(distinct: true).page(params[:page]).per(20)
  end

  def show
    @compliance_controls = @compliance_requirement.compliance_controls
  end

  def new
    @compliance_requirement = @compliance_framework.compliance_requirements.build
  end

  def create
    if params[:requirements].present?
      created_count = 0
      total_count = 0
      
      params[:requirements].each do |_, req_params|
        total_count += 1
        if req_params[:create] == "1"
          req = @compliance_framework.compliance_requirements.build(
            name: req_params[:name],
            description: req_params[:description],
            priority: req_params[:priority],
            requirement_type: req_params[:requirement_type],
            organization: @organization
          )
          created_count += 1 if req.save
        end
      end
      
      redirect_to organization_compliance_framework_path(@organization, @compliance_framework),
                  notice: "#{created_count} of #{total_count} suggested requirements were successfully created."
    else
      @compliance_requirement = @compliance_framework.compliance_requirements.build(compliance_requirement_params)
      @compliance_requirement.organization = @organization

      if @compliance_requirement.save
        redirect_to organization_compliance_framework_compliance_requirement_path(@organization, @compliance_framework, @compliance_requirement),
                    notice: 'Compliance requirement was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    old_risk_level = @compliance_requirement.risk_level

    if @compliance_requirement.update(compliance_requirement_params)
      # Send risk alert notification if risk level changed
      if old_risk_level != @compliance_requirement.risk_level && @compliance_requirement.risk_level.present?
        send_risk_alert_notification(@compliance_requirement, @compliance_requirement.risk_level)
      end

      redirect_to organization_compliance_framework_compliance_requirement_path(@organization, @compliance_framework, @compliance_requirement),
                  notice: 'Compliance requirement was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @compliance_requirement.destroy
    redirect_to organization_compliance_framework_compliance_requirements_path(@organization, @compliance_framework),
                notice: 'Compliance requirement was successfully deleted.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_compliance_framework
    @compliance_framework = @organization.compliance_frameworks.find(params[:compliance_framework_id])
  end

  def set_compliance_requirement
    @compliance_requirement = @compliance_framework.compliance_requirements.find(params[:id])
  end

  def compliance_requirement_params
    params.require(:compliance_requirement).permit(:name, :code, :description, :requirement_type, :priority, :status,
                                                   :risk_level, :settings)
  end

  def authorize_compliance_requirement
    case action_name
    when 'index'
      authorize ComplianceRequirement.new(compliance_framework: @compliance_framework, organization: @organization),
                :index?
    when 'show'
      authorize @compliance_requirement, :show?
    when 'new', 'create'
      authorize ComplianceRequirement.new(compliance_framework: @compliance_framework, organization: @organization),
                :create?
    when 'edit', 'update'
      authorize @compliance_requirement, :update?
    when 'destroy'
      authorize @compliance_requirement, :destroy?
    end
  end

  def send_risk_alert_notification(item, risk_level)
    # Notify organization admins
    @organization.users.joins(:roles).where(roles: { name: %w[org_admin super_admin] }).each do |admin|
      next if admin == current_user

      RiskAlertNotifier.with(
        item: item,
        risk_level: risk_level,
        alerted_by: current_user
      ).deliver_later(admin)
    end
  end
end
