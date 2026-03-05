class ExecutiveReportsController < ApplicationController
  before_action -> { require_feature!(:executive_reporting) }
  before_action :set_organization
  before_action :authorize_executive_reports

  def index
    @reports = ExecutiveReport.where(organization: @organization).recent.limit(20)
  end

  def show
    @report = ExecutiveReport.where(organization: @organization).find(params[:id])
  end

  def new
    @report = ExecutiveReport.new(
      period_start: 3.months.ago.beginning_of_quarter,
      period_end: Date.current
    )
  end

  def create
    service = ExecutiveReportService.new(@organization)
    report = service.generate(
      period_start: Date.parse(params[:period_start]),
      period_end: Date.parse(params[:period_end]),
      report_type: params[:report_type] || :quarterly,
      user: current_user
    )

    redirect_to organization_executive_report_path(@organization, report),
                notice: 'Executive report generated successfully.'
  rescue StandardError => e
    redirect_to organization_executive_reports_path(@organization),
                alert: "Report generation failed: #{e.message}"
  end

  def publish
    report = ExecutiveReport.where(organization: @organization).find(params[:id])
    report.update!(status: :published)
    redirect_to organization_executive_report_path(@organization, report),
                notice: 'Report published.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_executive_reports
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
