class ImpactSimulationsController < ApplicationController
  before_action -> { require_feature!(:regulatory_impact_simulation) }
  before_action :set_organization
  before_action :authorize_simulation

  def index
    @assessments = ImpactAssessment.where(organization: @organization).recent.limit(20)
    @regulations = Regulation.order(:title).limit(50)
  end

  def show
    @assessment = ImpactAssessment.where(organization: @organization).find(params[:id])
    @items = @assessment.impacted_items
    @effort = @assessment.impact_details['effort'] || {}
  end

  def simulate
    regulation = Regulation.find(params[:regulation_id])
    service = ImpactPredictionService.new(@organization)
    @assessment = service.run_assessment(regulation, user: current_user)

    redirect_to organization_impact_simulation_path(@organization, @assessment),
                notice: "Impact assessment completed. #{@assessment.impacted_controls_count} controls and #{@assessment.impacted_policies_count} policies affected."
  rescue StandardError => e
    redirect_to organization_impact_simulations_path(@organization),
                alert: "Simulation failed: #{e.message}"
  end

  def create_findings
    assessment = ImpactAssessment.where(organization: @organization).find(params[:id])
    service = ImpactPredictionService.new(@organization)
    findings = service.create_findings_from_assessment(assessment)

    redirect_to organization_impact_simulation_path(@organization, assessment),
                notice: "#{findings.size} findings created from high-impact items."
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_simulation
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
