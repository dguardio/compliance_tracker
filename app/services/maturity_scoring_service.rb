class MaturityScoringService
  # Weight distribution for composite score
  WEIGHTS = {
    testing: 0.30,
    evidence_freshness: 0.25,
    findings: 0.25,
    documentation: 0.20
  }.freeze

  # Score thresholds for maturity levels
  LEVEL_THRESHOLDS = {
    1 => 0..19,     # Ad-hoc
    2 => 20..39,    # Repeatable
    3 => 40..59,    # Defined
    4 => 60..79,    # Managed
    5 => 80..100    # Optimized
  }.freeze

  def initialize(organization)
    @organization = organization
  end

  # Score a single control and return level + breakdown
  def score_control(control)
    testing = testing_score(control)
    evidence = evidence_freshness_score(control)
    findings = finding_score(control)
    documentation = documentation_score(control)

    composite = (
      testing * WEIGHTS[:testing] +
      evidence * WEIGHTS[:evidence_freshness] +
      findings * WEIGHTS[:findings] +
      documentation * WEIGHTS[:documentation]
    ).round(2)

    level = composite_to_level(composite)

    {
      maturity_level: level,
      computed_score: composite,
      testing_score: testing,
      evidence_freshness_score: evidence,
      finding_score: findings,
      documentation_score: documentation,
      maturity_label: MaturitySnapshot::MATURITY_LEVELS[level]
    }
  end

  # Bulk compute + persist snapshots for all controls in an organization
  def snapshot_organization(snapshot_date = Date.current)
    controls = ComplianceControl.joins(:compliance_requirement)
                                .where(compliance_requirements: { compliance_framework_id: framework_ids })

    results = []

    controls.find_each do |control|
      score = score_control(control)

      snapshot = MaturitySnapshot.find_or_initialize_by(
        compliance_control: control,
        organization: @organization,
        snapshot_date: snapshot_date
      )

      # Generate AI commentary for improvement recommendations
      commentary = generate_commentary(control, score)

      snapshot.assign_attributes(
        maturity_level: score[:maturity_level],
        computed_score: score[:computed_score],
        testing_score: score[:testing_score],
        evidence_freshness_score: score[:evidence_freshness_score],
        finding_score: score[:finding_score],
        documentation_score: score[:documentation_score],
        ai_commentary: commentary
      )

      snapshot.save!

      # Update the control's maturity_level
      control.update_column(:maturity_level, score[:maturity_level])

      results << { control_id: control.id, **score, commentary: commentary }
    end

    results
  rescue StandardError => e
    Rails.logger.error "MaturityScoringService snapshot failed: #{e.message}"
    raise
  end

  # Organization-level summary stats
  def organization_summary
    controls = ComplianceControl.joins(:compliance_requirement)
                                .where(compliance_requirements: { compliance_framework_id: framework_ids })

    total = controls.count
    return default_summary if total.zero?

    distribution = controls.group(:maturity_level).count
    avg_level = controls.average(:maturity_level)&.round(1) || 1.0
    below_target = controls.where('maturity_level < target_maturity_level').count

    {
      total_controls: total,
      average_maturity: avg_level,
      distribution: (1..5).map { |l| { level: l, label: MaturitySnapshot::MATURITY_LEVELS[l], count: distribution[l] || 0 } },
      below_target: below_target,
      target_gap_percentage: ((below_target.to_f / total) * 100).round(1)
    }
  end

  private

  def framework_ids
    @framework_ids ||= @organization.compliance_frameworks.pluck(:id)
  end

  # Testing score (0-100): based on test plan existence, frequency, and pass rate
  def testing_score(control)
    plans = control.test_plans.where(status: :active)
    return 0 if plans.empty?

    has_plan = 25 # Base score for having an active test plan
    frequency_score = plans.any? { |p| p.frequency_monthly? || p.frequency_quarterly? } ? 25 : 10
    
    # Pass rate from most recent executions
    recent_executions = TestExecution.where(test_plan: plans)
                                      .where(status: [:completed, :reviewed])
                                      .order(created_at: :desc)
                                      .limit(5)

    if recent_executions.any?
      pass_count = recent_executions.where(result: :pass).count
      pass_rate = (pass_count.to_f / recent_executions.count) * 50
    else
      pass_rate = 0
    end

    [has_plan + frequency_score + pass_rate, 100].min.round(2)
  end

  # Evidence freshness score (0-100): based on linked documents' expiry status
  def evidence_freshness_score(control)
    documents = Document.joins(:evidence_requests)
                        .where(evidence_requests: { compliance_control_id: control.id })

    return 50 if documents.empty? # Neutral if no evidence required

    total = documents.count
    return 50 if total.zero?

    fresh = documents.where('expires_at IS NULL OR expires_at > ?', Date.current).count
    expiring_soon = documents.where('expires_at BETWEEN ? AND ?', Date.current, 30.days.from_now).count
    expired = documents.where('expires_at < ?', Date.current).count

    fresh_score = (fresh.to_f / total) * 80
    expiring_penalty = (expiring_soon.to_f / total) * 20
    expired_penalty = (expired.to_f / total) * 50

    [fresh_score + 20 - expiring_penalty - expired_penalty, 0].max.round(2)
  end

  # Finding score (0-100): fewer active findings = higher score
  def finding_score(control)
    total_findings = control.findings.count
    return 100 if total_findings.zero? # No findings = perfect score

    active = control.findings.where(status: [:open, :in_progress]).count
    closed = control.findings.where(status: [:closed, :accepted, :remediated]).count

    if active.zero?
      # All findings resolved
      90 + ([closed, 10].min) # Bonus for having resolved findings (shows maturity)
    else
      # Penalize for active findings
      severity_penalty = control.findings.where(status: [:open, :in_progress])
                                          .where(severity: [:critical, :high]).count * 15
      base = [(100 - (active * 20) - severity_penalty), 0].max
      base.round(2)
    end
  end

  # Documentation score (0-100): based on linked policies
  def documentation_score(control)
    requirement = control.compliance_requirement
    framework = requirement&.compliance_framework

    score = 0

    # Does the control have a description?
    score += 15 if control.description.present?

    # Are there linked policies for the requirement/framework?
    policies_count = PolicyLink.where(
      linkable_type: ['ComplianceRequirement', 'ComplianceFramework'],
      linkable_id: [requirement&.id, framework&.id].compact
    ).count

    score += [policies_count * 20, 60].min # Up to 60 for policies

    # Does the control have notes/procedures?
    score += 10 if control.settings&.dig('notes').present?
    score += 15 if control.settings&.dig('control_category').present?

    [score, 100].min
  end

  def composite_to_level(score)
    LEVEL_THRESHOLDS.each do |level, range|
      return level if range.include?(score.to_i)
    end
    1 # Default to Ad-hoc
  end

  def default_summary
    {
      total_controls: 0,
      average_maturity: 0,
      distribution: (1..5).map { |l| { level: l, label: MaturitySnapshot::MATURITY_LEVELS[l], count: 0 } },
      below_target: 0,
      target_gap_percentage: 0
    }
  end

  def generate_commentary(control, score)
    return nil if score[:computed_score] >= 80 # Level 5 controls don't need improvement advice

    prompt = <<~PROMPT
      Provide 2-3 specific improvement recommendations for the following compliance control.
      Be concrete and actionable. Keep total response under 100 words.

      Control: #{control.name}
      Current Maturity Level: #{score[:maturity_level]} (#{score[:maturity_label]})
      Score Breakdown:
      - Testing: #{score[:testing_score]}/100
      - Evidence Freshness: #{score[:evidence_freshness_score]}/100
      - Findings: #{score[:finding_score]}/100
      - Documentation: #{score[:documentation_score]}/100

      Focus recommendations on the weakest area(s).
    PROMPT

    response = Ai::Client.chat(prompt, task_type: :factual, agent_name: "MaturityCommentary")
    response.content.strip
  rescue => e
    Rails.logger.debug "[MaturityScoring] Commentary generation skipped: #{e.message}"
    nil
  end
end
