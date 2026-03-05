class MaturityController < ApplicationController
  before_action -> { require_feature!(:maturity_assessment) }
  before_action :set_organization
  before_action :authorize_maturity

  def index
    @service = MaturityScoringService.new(@organization)
    @summary = @service.organization_summary

    @controls = ComplianceControl.joins(:compliance_requirement)
                  .where(compliance_requirements: { compliance_framework_id: @organization.compliance_frameworks.pluck(:id) })
                  .includes(:compliance_requirement)
                  .order(:maturity_level)

    # Filter by framework
    if params[:framework_id].present?
      @controls = @controls.where(compliance_requirements: { compliance_framework_id: params[:framework_id] })
    end

    # Filter by maturity level
    if params[:maturity_level].present?
      @controls = @controls.where(maturity_level: params[:maturity_level])
    end

    # Filter to show only below-target
    if params[:below_target] == 'true'
      @controls = @controls.where('maturity_level < target_maturity_level')
    end

    @frameworks = @organization.compliance_frameworks
    @recent_snapshots = MaturitySnapshot.where(organization: @organization)
                                         .by_quarter
                                         .limit(8)
  end

  def show
    @control = ComplianceControl.find(params[:id])
    @service = MaturityScoringService.new(@organization)
    @current_score = @service.score_control(@control)

    @snapshots = MaturitySnapshot.where(compliance_control: @control, organization: @organization)
                                  .order(snapshot_date: :desc)
                                  .limit(12)

    @quarterly_trend = MaturitySnapshot.where(compliance_control: @control, organization: @organization)
                                        .by_quarter
  end

  def update
    @control = ComplianceControl.find(params[:id])

    if @control.update(target_maturity_level: params[:target_maturity_level].to_i)
      redirect_to organization_maturity_path(@organization, @control),
                  notice: "Target maturity updated to #{MaturitySnapshot::MATURITY_LEVELS[params[:target_maturity_level].to_i]}."
    else
      redirect_to organization_maturity_path(@organization, @control),
                  alert: 'Failed to update target maturity.'
    end
  end

  def snapshot
    service = MaturityScoringService.new(@organization)
    results = service.snapshot_organization

    redirect_to organization_maturity_index_path(@organization),
                notice: "Maturity scores computed for #{results.count} controls."
  rescue StandardError => e
    redirect_to organization_maturity_index_path(@organization),
                alert: "Scoring failed: #{e.message}"
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_maturity
    # Use a simple role check — compliance managers and above
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization) ||
           current_user.has_role?(:compliance_officer, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
