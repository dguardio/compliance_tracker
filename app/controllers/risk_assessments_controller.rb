class RiskAssessmentsController < ApplicationController
  before_action :set_organization
  before_action :set_compliance_framework, if: -> { params[:compliance_framework_id].present? }
  before_action :set_compliance_requirement, if: -> { params[:compliance_requirement_id].present? }
  before_action :set_compliance_control, if: -> { params[:compliance_control_id].present? }
  before_action :set_risk_assessment, only: %i[show edit update destroy]
  before_action :authorize_risk_assessment

  def index
    @risk_assessments = if @compliance_control
                          @compliance_control.risk_assessments.includes(:created_by, :assigned_to, :compliance_framework,
                                                                        :compliance_requirement)
                        elsif @compliance_requirement
                          @compliance_requirement.risk_assessments.includes(:created_by, :assigned_to, :compliance_framework,
                                                                            :compliance_control)
                        elsif @compliance_framework
                          @compliance_framework.risk_assessments.includes(:created_by, :assigned_to, :compliance_requirement,
                                                                          :compliance_control)
                        else
                          @organization.risk_assessments.includes(:created_by, :assigned_to, :compliance_framework,
                                                                  :compliance_requirement, :compliance_control)
                        end

    @risk_assessments = @risk_assessments.page(params[:page]).per(20)
  end

  def show
    @compliance_framework = @risk_assessment.compliance_framework
    @compliance_requirement = @risk_assessment.compliance_requirement
    @compliance_control = @risk_assessment.compliance_control
  end

  def new
    @risk_assessment = if @compliance_control
                         @compliance_control.risk_assessments.build
                       elsif @compliance_requirement
                         @compliance_requirement.risk_assessments.build
                       elsif @compliance_framework
                         @compliance_framework.risk_assessments.build
                       else
                         @organization.risk_assessments.build
                       end

    @risk_assessment.created_by = current_user
    @risk_assessment.assigned_to = current_user
    @risk_assessment.assessment_date = Date.current
    @risk_assessment.next_review_date = 1.year.from_now.to_date
  end

  def create
    @risk_assessment = if @compliance_control
                         @compliance_control.risk_assessments.build(risk_assessment_params)
                       elsif @compliance_requirement
                         @compliance_requirement.risk_assessments.build(risk_assessment_params)
                       elsif @compliance_framework
                         @compliance_framework.risk_assessments.build(risk_assessment_params)
                       else
                         @organization.risk_assessments.build(risk_assessment_params)
                       end

    @risk_assessment.created_by = current_user

    if @risk_assessment.save
      # Send notifications
      send_risk_assessment_notifications(:created)

      redirect_to risk_assessment_path(@risk_assessment), notice: 'Risk assessment was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    old_assigned_to = @risk_assessment.assigned_to
    old_risk_level = @risk_assessment.risk_level

    if @risk_assessment.update(risk_assessment_params)
      # Send notifications
      send_risk_assessment_notifications(:updated, old_assigned_to, old_risk_level)

      redirect_to risk_assessment_path(@risk_assessment), notice: 'Risk assessment was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @risk_assessment.destroy
    redirect_to risk_assessments_path, notice: 'Risk assessment was successfully deleted.'
  end

  private

  helper_method :risk_assessments_path, :risk_assessment_path

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
    @compliance_control = @compliance_requirement.compliance_controls.find(params[:compliance_control_id])
  end

  def set_risk_assessment
    @risk_assessment = if @compliance_control
                         @compliance_control.risk_assessments.find(params[:id])
                       elsif @compliance_requirement
                         @compliance_requirement.risk_assessments.find(params[:id])
                       elsif @compliance_framework
                         @compliance_framework.risk_assessments.find(params[:id])
                       else
                         @organization.risk_assessments.find(params[:id])
                       end
  end

  def risk_assessment_params
    params.require(:risk_assessment).permit(
      :name, :description, :likelihood, :impact, :status,
      :assessment_date, :next_review_date, :mitigation_plan,
      :assigned_to_id, :compliance_framework_id, :compliance_requirement_id, :compliance_control_id
    )
  end

  def authorize_risk_assessment
    case action_name
    when 'index'
      authorize RiskAssessment.new(organization: @organization), :index?
    when 'show'
      authorize @risk_assessment, :show?
    when 'new', 'create'
      authorize RiskAssessment.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @risk_assessment, :update?
    when 'destroy'
      authorize @risk_assessment, :destroy?
    end
  end

  def risk_assessments_path
    if @compliance_control
      organization_compliance_framework_compliance_requirement_compliance_control_risk_assessments_path(@organization,
                                                                                                        @compliance_framework, @compliance_requirement, @compliance_control)
    elsif @compliance_requirement
      organization_compliance_framework_compliance_requirement_risk_assessments_path(@organization,
                                                                                     @compliance_framework, @compliance_requirement)
    elsif @compliance_framework
      organization_compliance_framework_risk_assessments_path(@organization, @compliance_framework)
    else
      organization_risk_assessments_path(@organization)
    end
  end

  def risk_assessment_path(risk_assessment)
    if @compliance_control
      organization_compliance_framework_compliance_requirement_compliance_control_risk_assessment_path(@organization,
                                                                                                       @compliance_framework, @compliance_requirement, @compliance_control, risk_assessment)
    elsif @compliance_requirement
      organization_compliance_framework_compliance_requirement_risk_assessment_path(@organization,
                                                                                    @compliance_framework, @compliance_requirement, risk_assessment)
    elsif @compliance_framework
      organization_compliance_framework_risk_assessment_path(@organization, @compliance_framework, risk_assessment)
    else
      organization_risk_assessment_path(@organization, risk_assessment)
    end
  end

  def send_risk_assessment_notifications(action, old_assigned_to = nil, old_risk_level = nil)
    # Notify assigned user
    if @risk_assessment.assigned_to && @risk_assessment.assigned_to != current_user
      RiskAssessmentNotificationNotifier.with(
        risk_assessment: @risk_assessment,
        action: action,
        actor: current_user
      ).deliver_later(@risk_assessment.assigned_to)
    end

    # Notify if assigned to different user
    if action == :updated && old_assigned_to && @risk_assessment.assigned_to != old_assigned_to
      RiskAssessmentNotificationNotifier.with(
        risk_assessment: @risk_assessment,
        action: :assigned,
        actor: current_user
      ).deliver_later(@risk_assessment.assigned_to)
    end

    # Notify if risk level changed to high
    if action == :updated && old_risk_level && @risk_assessment.risk_level == 'high' && old_risk_level != 'high'
      RiskAssessmentNotificationNotifier.with(
        risk_assessment: @risk_assessment,
        action: :high_risk,
        actor: current_user
      ).deliver_later(@risk_assessment.assigned_to)
    end

    # Notify organization admins for high risk assessments
    return unless @risk_assessment.risk_level == 'high'

    @organization.users.joins(:roles).where(roles: { name: %w[org_admin super_admin] }).each do |admin|
      next if admin == current_user

      RiskAssessmentNotificationNotifier.with(
        risk_assessment: @risk_assessment,
        action: :high_risk,
        actor: current_user
      ).deliver_later(admin)
    end
  end
end
