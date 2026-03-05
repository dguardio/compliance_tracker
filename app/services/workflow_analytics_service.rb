class WorkflowAnalyticsService
  def initialize(organization)
    @organization = organization
  end

  # Average/median time-to-close findings by severity, quarter
  def findings_velocity(period_months: 12)
    findings = @organization.findings
                  .where(status: [:closed, :accepted, :remediated])
                  .where('resolved_at IS NOT NULL')
                  .where('created_at > ?', period_months.months.ago)

    return default_velocity if findings.empty?

    # By severity
    by_severity = {}
    Finding.severities.keys.each do |sev|
      sev_findings = findings.where(severity: sev)
      durations = sev_findings.map { |f| ((f.resolved_at - f.created_at) / 1.day).round(1) }
      by_severity[sev] = {
        count: durations.size,
        avg_days: durations.any? ? (durations.sum / durations.size).round(1) : 0,
        median_days: durations.any? ? median(durations).round(1) : 0
      }
    end

    # By quarter
    by_quarter = findings
      .group("DATE_TRUNC('quarter', created_at)")
      .count
      .transform_keys { |k| k.strftime('%Y Q%q') rescue k.to_s }

    # Overall
    all_durations = findings.map { |f| ((f.resolved_at - f.created_at) / 1.day).round(1) }

    {
      by_severity: by_severity,
      by_quarter: by_quarter,
      overall: {
        total_closed: all_durations.size,
        avg_days: all_durations.any? ? (all_durations.sum / all_durations.size).round(1) : 0,
        median_days: all_durations.any? ? median(all_durations).round(1) : 0,
        fastest: all_durations.min || 0,
        slowest: all_durations.max || 0
      }
    }
  end

  # Identify which users/departments have the most pending items (bottlenecks)
  def bottleneck_detection
    # Pending findings by assignee
    finding_bottlenecks = @organization.findings
      .where(status: [:open, :in_progress])
      .includes(:assigned_to)
      .group_by { |f| f.assigned_to || OpenStruct.new(id: nil, full_name: 'Unassigned', email: 'unassigned') }
      .map do |user, findings|
        avg_age = findings.map { |f| (Date.current - f.created_at.to_date).to_i }.then { |ages| ages.any? ? (ages.sum.to_f / ages.size).round(1) : 0 }
        {
          user: user,
          pending_count: findings.size,
          avg_age_days: avg_age,
          critical_count: findings.count { |f| f.severity_critical? || f.severity_high? },
          overdue_count: findings.count(&:overdue?)
        }
      end
      .sort_by { |b| -b[:pending_count] }

    # Pending test executions
    test_bottlenecks = TestExecution.joins(test_plan: :compliance_control)
      .joins("LEFT JOIN users ON users.id = test_executions.tester_id")
      .where(test_plans: { organization_id: @organization.id })
      .where(status: [:not_started, :in_progress])
      .group(:tester_id)
      .count
      .map { |tester_id, count| { user_id: tester_id, pending_tests: count } }

    # Pending attestations
    attestation_bottlenecks = Attestation.joins(attestation_campaign: :organization)
      .where(attestation_campaigns: { organization_id: @organization.id })
      .where(status: :pending)
      .group(:user_id)
      .count
      .map { |user_id, count| { user_id: user_id, pending_attestations: count } }

    {
      findings: finding_bottlenecks.first(10),
      tests: test_bottlenecks.sort_by { |b| -b[:pending_tests] }.first(10),
      attestations: attestation_bottlenecks.sort_by { |b| -b[:pending_attestations] }.first(10)
    }
  end

  # Framework coverage over time + projected completion
  def framework_coverage_velocity
    frameworks = @organization.compliance_frameworks.includes(:compliance_requirements)

    frameworks.map do |framework|
      total_requirements = framework.compliance_requirements.count
      covered = framework.compliance_requirements
                  .joins(:compliance_controls)
                  .where(compliance_controls: { status: :implemented })
                  .distinct.count

      coverage_pct = total_requirements > 0 ? ((covered.to_f / total_requirements) * 100).round(1) : 0

      {
        framework: framework,
        total_requirements: total_requirements,
        covered_requirements: covered,
        coverage_percentage: coverage_pct,
        gap_count: total_requirements - covered
      }
    end
  end

  # Open items per user across all modules
  def workload_distribution
    users = @organization.users.includes(:roles)

    users.map do |user|
      open_findings = @organization.findings.where(assigned_to: user, status: [:open, :in_progress]).count
      pending_tests = TestExecution.joins(test_plan: :compliance_control)
                        .where(test_plans: { organization_id: @organization.id })
                        .where(tester_id: user.id, status: [:not_started, :in_progress])
                        .count
      pending_attestations = Attestation.joins(attestation_campaign: :organization)
                               .where(attestation_campaigns: { organization_id: @organization.id })
                               .where(user_id: user.id, status: :pending)
                               .count
      total = open_findings + pending_tests + pending_attestations

      {
        user: user,
        open_findings: open_findings,
        pending_tests: pending_tests,
        pending_attestations: pending_attestations,
        total_items: total,
        overloaded: total > 10
      }
    end.sort_by { |w| -w[:total_items] }
  end

  private

  def median(array)
    return 0 if array.empty?
    sorted = array.sort
    mid = sorted.length / 2
    sorted.length.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
  end

  def default_velocity
    {
      by_severity: {},
      by_quarter: {},
      overall: { total_closed: 0, avg_days: 0, median_days: 0, fastest: 0, slowest: 0 }
    }
  end
end
