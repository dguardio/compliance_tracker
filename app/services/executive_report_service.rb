class ExecutiveReportService
  def initialize(organization)
    @organization = organization
  end

  # Generate a full report for a given period
  def generate(period_start:, period_end:, report_type: :quarterly, user: nil)
    metrics = collect_metrics(period_start, period_end)
    narrative = generate_narrative(metrics, period_start, period_end)

    ExecutiveReport.create!(
      organization: @organization,
      title: "#{report_type.to_s.titleize} Compliance Report — #{period_start.strftime('%b %Y')} to #{period_end.strftime('%b %Y')}",
      report_type: report_type,
      period_start: period_start,
      period_end: period_end,
      narrative: narrative,
      metrics: metrics,
      status: :draft,
      generated_by: user
    )
  end

  private

  def collect_metrics(period_start, period_end)
    {
      'compliance_score' => compliance_score,
      'findings' => findings_metrics(period_start, period_end),
      'testing' => testing_metrics(period_start, period_end),
      'evidence' => evidence_metrics,
      'incidents' => incident_metrics(period_start, period_end),
      'attestations' => attestation_metrics(period_start, period_end),
      'maturity' => maturity_metrics
    }
  end

  def compliance_score
    frameworks = @organization.compliance_frameworks
    return 0 if frameworks.empty?

    scores = frameworks.map do |fw|
      total = fw.compliance_requirements.count
      covered = fw.compliance_requirements.joins(:compliance_controls)
                    .where(compliance_controls: { status: :implemented }).distinct.count
      total > 0 ? (covered.to_f / total * 100) : 0
    end

    (scores.sum / scores.size).round(1)
  end

  def findings_metrics(period_start, period_end)
    period_findings = @organization.findings.where(created_at: period_start..period_end)
    resolved = @organization.findings.where(resolved_at: period_start..period_end)

    {
      'opened' => period_findings.count,
      'closed' => resolved.count,
      'active' => @organization.findings.where(status: [:open, :in_progress]).count,
      'overdue' => @organization.findings.where(status: [:open, :in_progress]).where('sla_deadline < ?', Time.current).count,
      'avg_resolution_days' => avg_resolution(resolved)
    }
  end

  def testing_metrics(period_start, period_end)
    executions = TestExecution.joins(test_plan: :organization)
                    .where(test_plans: { organization_id: @organization.id })
                    .where(created_at: period_start..period_end)

    {
      'total_executions' => executions.count,
      'passed' => executions.where(result: :pass).count,
      'failed' => executions.where(result: :fail).count,
      'pass_rate' => executions.any? ? ((executions.where(result: :pass).count.to_f / executions.count) * 100).round(1) : 0
    }
  end

  def evidence_metrics
    documents = @organization.documents
    {
      'total' => documents.count,
      'fresh' => documents.where('expires_at IS NULL OR expires_at > ?', Date.current).count,
      'expiring_soon' => documents.where('expires_at BETWEEN ? AND ?', Date.current, 30.days.from_now).count,
      'expired' => documents.where('expires_at < ?', Date.current).count
    }
  end

  def incident_metrics(period_start, period_end)
    incidents = @organization.incidents.where(created_at: period_start..period_end)
    {
      'total' => incidents.count,
      'critical' => incidents.where(severity: :critical).count,
      'resolved' => incidents.where(status: [:resolved, :closed]).count
    }
  end

  def attestation_metrics(period_start, period_end)
    campaigns = @organization.attestation_campaigns.where(created_at: period_start..period_end)
    {
      'campaigns' => campaigns.count,
      'avg_completion' => campaigns.any? ? campaigns.map(&:completion_rate).sum / campaigns.count : 0
    }
  end

  def maturity_metrics
    avg = ComplianceControl.joins(:compliance_requirement)
            .where(compliance_requirements: { compliance_framework_id: @organization.compliance_frameworks.pluck(:id) })
            .average(:maturity_level)

    { 'average_maturity' => avg&.round(1) || 0 }
  end

  def avg_resolution(resolved)
    return 0 if resolved.empty?
    durations = resolved.where('resolved_at IS NOT NULL').map { |f| ((f.resolved_at - f.created_at) / 1.day).round(1) }
    durations.any? ? (durations.sum / durations.size).round(1) : 0
  end

  def generate_narrative(metrics, period_start, period_end)
    period = "#{period_start.strftime('%B %Y')} to #{period_end.strftime('%B %Y')}"

    prompt = <<~PROMPT
      You are a Chief Compliance Officer writing a board-level executive summary.
      Generate a professional, polished compliance report narrative for the period #{period}.

      Use the following real metrics data to inform your analysis. Include specific numbers, 
      identify trends, highlight risks, and provide actionable recommendations.

      **Compliance Score**: #{metrics['compliance_score']}%

      **Findings & Remediation**:
      - New findings opened: #{metrics['findings']['opened']}
      - Findings closed/resolved: #{metrics['findings']['closed']}
      - Currently active findings: #{metrics['findings']['active']}
      - Overdue (past SLA): #{metrics['findings']['overdue']}
      - Average resolution time: #{metrics['findings']['avg_resolution_days']} days

      **Control Testing**:
      - Tests executed: #{metrics['testing']['total_executions']}
      - Passed: #{metrics['testing']['passed']}
      - Failed: #{metrics['testing']['failed']}
      - Pass rate: #{metrics['testing']['pass_rate']}%

      **Evidence Health**:
      - Total documents: #{metrics['evidence']['total']}
      - Fresh/current: #{metrics['evidence']['fresh']}
      - Expiring within 30 days: #{metrics['evidence']['expiring_soon']}
      - Expired: #{metrics['evidence']['expired']}

      **Incidents**:
      - Total reported: #{metrics['incidents']['total']}
      - Critical incidents: #{metrics['incidents']['critical']}
      - Resolved: #{metrics['incidents']['resolved']}

      **Policy Attestations**:
      - Campaigns: #{metrics['attestations']['campaigns']}
      - Average completion rate: #{metrics['attestations']['avg_completion']}%

      **Control Maturity**:
      - Average maturity level: #{metrics['maturity']['average_maturity']} / 5.0

      **Format your response as markdown with these sections:**
      ## Executive Summary
      ## Findings & Remediation
      ## Control Testing & Assurance
      ## Evidence Health
      ## Incidents & Response
      ## Control Maturity
      ## Recommendations & Next Steps

      Be specific with numbers. Flag any metrics that represent risk (e.g., overdue findings, low pass rates, expired evidence).
      End with 3-5 concrete, actionable recommendations prioritized by impact.
    PROMPT

    response = Ai::Client.chat(
      prompt,
      task_type: :drafting,
      agent_name: "ExecutiveReportNarrative",
      temperature: 0.6
    )

    response.content
  rescue => e
    Rails.logger.error "[ExecutiveReportService] AI narrative generation failed: #{e.message}. Falling back to template."
    generate_template_narrative(metrics, period_start, period_end)
  end

  # Fallback template narrative if LLM is unavailable
  def generate_template_narrative(metrics, period_start, period_end)
    period = "#{period_start.strftime('%B %Y')} to #{period_end.strftime('%B %Y')}"
    findings = metrics['findings']
    testing = metrics['testing']

    <<~NARRATIVE
      ## Executive Summary

      During the period #{period}, the organization maintained a compliance score of **#{metrics['compliance_score']}%** 
      across all active frameworks.

      ## Findings & Remediation

      A total of **#{findings['opened']}** new findings were identified and **#{findings['closed']}** were resolved. 
      There are currently **#{findings['active']}** active findings, of which **#{findings['overdue']}** are overdue. 
      The average time to remediation was **#{findings['avg_resolution_days']} days**.

      ## Control Testing

      **#{testing['total_executions']}** control tests were executed with a **#{testing['pass_rate']}%** pass rate 
      (#{testing['passed']} passed, #{testing['failed']} failed).

      ## Evidence Health

      The evidence library contains **#{metrics['evidence']['total']}** documents. 
      **#{metrics['evidence']['expired']}** are expired and **#{metrics['evidence']['expiring_soon']}** are expiring within 30 days.

      ## Incidents

      **#{metrics['incidents']['total']}** incidents were reported, including **#{metrics['incidents']['critical']}** critical incidents. 
      **#{metrics['incidents']['resolved']}** have been resolved.

      ## Control Maturity

      The average control maturity level is **#{metrics['maturity']['average_maturity']}** out of 5.0.

      ---
      *This report was auto-generated using a template fallback. AI narrative generation was unavailable.*
    NARRATIVE
  end
end
