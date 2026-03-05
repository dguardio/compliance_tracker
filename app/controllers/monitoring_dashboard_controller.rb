class MonitoringDashboardController < ApplicationController
  before_action -> { require_feature!(:continuous_monitoring) }
  before_action :set_organization
  before_action :authorize_monitoring

  def index
    # Aggregate status across all modules
    @status = {
      evidence_checks: evidence_check_status,
      vendor_alerts: vendor_alerts,
      finding_summary: finding_summary,
      framework_health: framework_health,
      recent_activity: recent_activity
    }
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def evidence_check_status
    checks = EvidenceCheck.where(organization: @organization)
    {
      total: checks.count,
      passing: checks.where(last_result: :pass).count,
      failing: checks.where(last_result: :fail).count,
      stale: checks.overdue.count
    }
  end

  def vendor_alerts
    vendors = Vendor.where(organization: @organization)
    {
      total: vendors.count,
      critical_tier: vendors.where(risk_tier: :critical).count,
      contracts_expiring: vendors.contracts_expiring(30).count,
      overdue_assessments: VendorAssessment.where(organization: @organization)
                             .where('next_review_date < ?', Date.current).count
    }
  end

  def finding_summary
    findings = @organization.findings
    {
      open: findings.where(status: [:open, :in_progress]).count,
      critical: findings.where(status: [:open, :in_progress], severity: :critical).count,
      overdue: findings.where(status: [:open, :in_progress]).where('sla_deadline < ?', Time.current).count,
      closed_this_month: findings.where(resolved_at: Date.current.beginning_of_month..Date.current).count
    }
  end

  def framework_health
    @organization.compliance_frameworks.map do |fw|
      total = fw.compliance_requirements.count
      covered = fw.compliance_requirements.joins(:compliance_controls)
                    .where(compliance_controls: { status: :implemented }).distinct.count

      {
        name: fw.name,
        coverage: total > 0 ? ((covered.to_f / total) * 100).round(0) : 0,
        total: total,
        covered: covered
      }
    end
  end

  def recent_activity
    # Last 10 significant events across all modules
    activities = []

    @organization.findings.order(created_at: :desc).limit(3).each do |f|
      activities << { type: 'finding', text: "Finding: #{f.title}", time: f.created_at, icon: 'fas fa-bug', color: 'red' }
    end

    TestExecution.joins(test_plan: :organization)
      .where(test_plans: { organization_id: @organization.id })
      .order(created_at: :desc).limit(3).each do |te|
      activities << { type: 'test', text: "Test: #{te.test_plan.title} — #{te.result}", time: te.created_at, icon: 'fas fa-vial', color: 'blue' }
    end

    @organization.incidents.order(created_at: :desc).limit(2).each do |i|
      activities << { type: 'incident', text: "Incident: #{i.title}", time: i.created_at, icon: 'fas fa-exclamation-circle', color: 'orange' }
    end

    activities.sort_by { |a| -a[:time].to_i }.first(10)
  end

  def authorize_monitoring
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization) ||
           current_user.has_role?(:compliance_officer, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
