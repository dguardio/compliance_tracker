class ComplianceControlsController < ApplicationController
  before_action :set_organization
  before_action :set_compliance_framework
  before_action :set_compliance_requirement
  before_action :set_compliance_control, only: %i[show edit update destroy assignment_form assign]
  before_action :authorize_compliance_control

  def index
    @compliance_controls = @compliance_requirement.compliance_controls
  end

  def show
  end

  def new
    @compliance_control = @compliance_requirement.compliance_controls.build
  end

  def create
    @compliance_control = @compliance_requirement.compliance_controls.build(compliance_control_params)
    @compliance_control.organization = @organization

    if @compliance_control.save
      redirect_to organization_compliance_framework_compliance_requirement_compliance_control_path(@organization, @compliance_framework, @compliance_requirement, @compliance_control),
                  notice: 'Compliance control was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    old_effectiveness = @compliance_control.effectiveness

    if @compliance_control.update(compliance_control_params)
      # Send risk alert notification if effectiveness changed to low
      if old_effectiveness != @compliance_control.effectiveness && @compliance_control.effectiveness == 'low'
        send_risk_alert_notification(@compliance_control, 'low effectiveness')
      end

      redirect_to organization_compliance_framework_compliance_requirement_compliance_control_path(@organization, @compliance_framework, @compliance_requirement, @compliance_control),
                  notice: 'Compliance control was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @compliance_control.destroy
    redirect_to organization_compliance_framework_compliance_requirement_compliance_controls_path(@organization, @compliance_framework, @compliance_requirement),
                notice: 'Compliance control was successfully deleted.'
  end

  def assignment_form
    @users = @organization.users.order(:first_name, :last_name)
    render partial: 'assignment_form'
  end

  def assign
    assignee_id = params.dig(:compliance_control, :assignee_id)
    due_date = params.dig(:compliance_control, :due_date)

    if @compliance_control.update(assignee_id: assignee_id, due_date: due_date)
      # Send notification to assignee
      ControlAssignedNotifier.with(compliance_control: @compliance_control, assigned_by: current_user).deliver_later(@compliance_control.assignee)
      
      redirect_to organization_compliance_framework_compliance_requirement_path(@organization, @compliance_framework, @compliance_requirement),
                  notice: "Control was successfully assigned to #{@compliance_control.assignee.full_name}."
    else
      # Handle error
      redirect_to organization_compliance_framework_compliance_requirement_path(@organization, @compliance_framework, @compliance_requirement),
                  alert: "Failed to assign control."
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_compliance_framework
    @compliance_framework = @organization.compliance_frameworks.find(params[:compliance_framework_id])
  end

  def set_compliance_requirement
    @compliance_requirement = @compliance_framework.compliance_requirements.find(params[:compliance_requirement_id])
  end

  def set_compliance_control
    @compliance_control = @compliance_requirement.compliance_controls.find(params[:id])
  end

  def compliance_control_params
    params.require(:compliance_control).permit(:name, :control_type, :description, :effectiveness, :status, :settings, :assignee_id, :due_date)
  end

  def authorize_compliance_control
    case action_name
    when 'index'
      authorize ComplianceControl.new(compliance_requirement: @compliance_requirement, organization: @organization),
                :index?
    when 'show'
      authorize @compliance_control, :show?
    when 'new', 'create'
      authorize ComplianceControl.new(compliance_requirement: @compliance_requirement, organization: @organization),
                :create?
    when 'edit', 'update'
      authorize @compliance_control, :update?
    when 'destroy'
      authorize @compliance_control, :destroy?
    when 'assignment_form', 'assign'
      authorize @compliance_control, :update? # Reuse update policy for assigning
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
