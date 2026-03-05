class RiskDashboardController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_feature!(:risk_management) }
  before_action :ensure_user_has_organization

  def index
    @organization = current_user.organization

    # Risk statistics
    @risk_stats = {
      total_requirements: @organization.compliance_requirements.count,
      high_risk_requirements: @organization.compliance_requirements.risk_high.count,
      medium_risk_requirements: @organization.compliance_requirements.risk_medium.count,
      low_risk_requirements: @organization.compliance_requirements.risk_low.count,
      critical_risk_requirements: @organization.compliance_requirements.risk_critical.count,
      total_controls: @organization.compliance_controls.count,
      effective_controls: @organization.compliance_controls.high.count,
      ineffective_controls: @organization.compliance_controls.low.count
    }

    # Risk by framework
    @risk_by_framework = @organization.compliance_frameworks.includes(:compliance_requirements).map do |framework|
      {
        framework: framework,
        requirements: framework.compliance_requirements.count,
        high_risk: framework.compliance_requirements.risk_high.count,
        medium_risk: framework.compliance_requirements.risk_medium.count,
        low_risk: framework.compliance_requirements.risk_low.count,
        critical_risk: framework.compliance_requirements.risk_critical.count
      }
    end

    # Recent high-risk items
    @high_risk_requirements = @organization.compliance_requirements.risk_high.includes(:compliance_framework).limit(10)
    @high_risk_controls = @organization.compliance_controls.risk_high.includes(:compliance_requirement).limit(10)

    # Risk trends (placeholder for future implementation)
    @risk_trends = []
  end

  def my_risks
    @organization = current_user.organization
    @risk_assessments = @organization.risk_assessments
                                     .where(assigned_to: current_user)
                                     .includes(:compliance_framework, :compliance_requirement, :compliance_control)
                                     .order(risk_score: :desc)
                                     .page(params[:page]).per(20)
  end

  def organization_risks
    @organization = current_user.organization
    @risk_assessments = @organization.risk_assessments
                                     .includes(:assigned_to, :compliance_framework, :compliance_requirement, :compliance_control)
                                     .order(risk_score: :desc)
                                     .page(params[:page]).per(20)
  end

  private

  def ensure_user_has_organization
    return if current_user.organization

    redirect_to new_organization_path, alert: 'You must be part of an organization to access the risk dashboard.'
  end
end
