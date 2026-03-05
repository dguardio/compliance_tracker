class WorkflowAnalyticsController < ApplicationController
  before_action -> { require_feature!(:workflow_intelligence) }
  before_action :set_organization
  before_action :authorize_analytics

  def index
    @service = WorkflowAnalyticsService.new(@organization)
    @velocity = @service.findings_velocity
    @coverage = @service.framework_coverage_velocity
  end

  def bottlenecks
    @service = WorkflowAnalyticsService.new(@organization)
    @bottlenecks = @service.bottleneck_detection
  end

  def workload
    @service = WorkflowAnalyticsService.new(@organization)
    @distribution = @service.workload_distribution
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_analytics
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
