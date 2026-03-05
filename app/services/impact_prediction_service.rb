class ImpactPredictionService
  def initialize(organization)
    @organization = organization
  end

  # Predict which controls, policies, and obligations are impacted by a regulation
  def predict(regulation)
    reg_text = [regulation.title, regulation.description].compact.join(' ')
    reg_embedding = Ai::Client.embed(reg_text, agent_name: "ImpactPrediction")

    items = []

    # Check controls
    controls = ComplianceControl.joins(:compliance_requirement)
                  .where(compliance_requirements: { compliance_framework_id: @organization.compliance_frameworks.pluck(:id) })
                  .includes(:compliance_requirement)

    controls.find_each do |control|
      score = semantic_similarity(reg_embedding, reg_text, control.name.to_s + ' ' + control.description.to_s)
      next if score < 0.15

      items << {
        type: 'control',
        id: control.id,
        name: control.name,
        description: control.description&.truncate(100),
        framework: control.compliance_requirement&.compliance_framework&.name,
        similarity_score: score,
        impact_level: score_to_level(score)
      }
    end

    # Check policies
    @organization.policies.find_each do |policy|
      score = semantic_similarity(reg_embedding, reg_text, policy.title.to_s + ' ' + policy.description.to_s)
      next if score < 0.15

      items << {
        type: 'policy',
        id: policy.id,
        name: policy.title,
        description: policy.description&.truncate(100),
        similarity_score: score,
        impact_level: score_to_level(score)
      }
    end

    # Check obligations
    @organization.obligations.find_each do |obligation|
      score = semantic_similarity(reg_embedding, reg_text, obligation.title.to_s + ' ' + obligation.description.to_s)
      next if score < 0.15

      items << {
        type: 'obligation',
        id: obligation.id,
        name: obligation.title,
        description: obligation.description&.truncate(100),
        similarity_score: score,
        impact_level: score_to_level(score)
      }
    end

    items.sort_by { |i| -i[:similarity_score] }
  end

  # Estimate remediation effort based on impact and historical velocity
  def estimate_effort(items)
    return { total_hours: 0, breakdown: {} } if items.empty?

    # Base hours per impact level
    hours_per_level = { 'high' => 16, 'medium' => 8, 'low' => 4 }

    # Adjust based on historical remediation velocity
    avg_days = avg_remediation_days
    velocity_multiplier = avg_days > 0 ? [avg_days / 5.0, 3.0].min : 1.0

    breakdown = items.group_by { |i| i[:impact_level] }.transform_values do |group|
      base = group.size * hours_per_level[group.first[:impact_level]]
      (base * velocity_multiplier).round(1)
    end

    {
      total_hours: breakdown.values.sum.round(1),
      breakdown: breakdown,
      velocity_multiplier: velocity_multiplier.round(2),
      avg_remediation_days: avg_days,
      item_count: items.size,
      high_impact: items.count { |i| i[:impact_level] == 'high' },
      medium_impact: items.count { |i| i[:impact_level] == 'medium' },
      low_impact: items.count { |i| i[:impact_level] == 'low' }
    }
  end

  # Create an ImpactAssessment record with full analysis
  def run_assessment(regulation, user: nil)
    items = predict(regulation)
    effort = estimate_effort(items)
    diff_service = RegulationDiffService.new(@organization)
    diff_result = diff_service.diff(regulation)

    assessment = ImpactAssessment.create!(
      organization: @organization,
      regulation: regulation,
      assessed_by: user,
      status: :completed,
      impacted_controls_count: items.count { |i| i[:type] == 'control' },
      impacted_policies_count: items.count { |i| i[:type] == 'policy' },
      estimated_effort_hours: effort[:total_hours],
      ai_summary: generate_summary(regulation, items, effort),
      impact_details: { items: items, effort: effort },
      diff_data: diff_result
    )

    assessment
  end

  # Auto-create findings for high-impact items
  def create_findings_from_assessment(assessment)
    return [] unless Flipper.enabled?(:findings_remediation, @organization)

    findings = []
    assessment.high_impact_items.each do |item|
      next unless item['type'] == 'control'

      control = ComplianceControl.find_by(id: item['id'])
      next unless control

      # Avoid duplicates
      existing = Finding.where(
        organization: @organization,
        compliance_control: control,
        source: :audit
      ).where.not(status: [:closed, :accepted])
      next if existing.exists?

      finding = Finding.create!(
        organization: @organization,
        compliance_control: control,
        compliance_requirement: control.compliance_requirement,
        compliance_framework: control.compliance_requirement&.compliance_framework,
        title: "Regulatory impact: #{assessment.regulation.title} affects #{control.name}",
        description: "Impact assessment identified this control as highly impacted by regulatory changes in #{assessment.regulation.title}.",
        source: :audit,
        severity: :high,
        status: :open
      )
      findings << finding
    end

    findings
  end

  private

  def semantic_similarity(reg_embedding, reg_text, item_text)
    return keyword_similarity_fallback(reg_text, item_text) unless reg_embedding.present?

    item_embedding = Ai::Client.embed(item_text, agent_name: "ImpactPrediction")
    return keyword_similarity_fallback(reg_text, item_text) unless item_embedding.present?

    # Cosine similarity
    dot = reg_embedding.zip(item_embedding).sum { |a, b| a * b }
    mag_r = Math.sqrt(reg_embedding.sum { |x| x**2 })
    mag_i = Math.sqrt(item_embedding.sum { |x| x**2 })
    mag_r > 0 && mag_i > 0 ? (dot / (mag_r * mag_i)).clamp(0, 1) : 0
  rescue => e
    Rails.logger.warn "[ImpactPrediction] Embedding similarity failed: #{e.message}"
    keyword_similarity_fallback(reg_text, item_text)
  end

  def keyword_similarity_fallback(reg_text, item_text)
    reg_words = reg_text.downcase.split(/\W+/).uniq.reject { |w| w.length < 3 }
    text_words = item_text.downcase.split(/\W+/).uniq.reject { |w| w.length < 3 }
    return 0 if text_words.empty? || reg_words.empty?

    overlap = (reg_words & text_words).size
    overlap.to_f / [reg_words.size, text_words.size].min
  end

  def score_to_level(score)
    if score >= 0.4
      'high'
    elsif score >= 0.25
      'medium'
    else
      'low'
    end
  end

  def avg_remediation_days
    resolved = @organization.findings.where(status: [:closed, :remediated]).where('resolved_at IS NOT NULL').limit(50)
    return 5 if resolved.empty?

    durations = resolved.map { |f| ((f.resolved_at - f.created_at) / 1.day).round(1) }
    (durations.sum / durations.size).round(1)
  end

  def generate_summary(regulation, items, effort)
    high = items.count { |i| i[:impact_level] == 'high' }
    medium = items.count { |i| i[:impact_level] == 'medium' }
    low = items.count { |i| i[:impact_level] == 'low' }

    # Use LLM for intelligent summary
    top_items = items.first(5).map { |i| "#{i[:type]}: #{i[:name]} (#{i[:impact_level]} impact)" }.join("\n")

    prompt = <<~PROMPT
      Summarize the following regulatory impact assessment in 3-4 sentences suitable for a compliance dashboard.
      Be specific about the numbers and highlight the most critical items.

      Regulation: #{regulation.title}
      Total items affected: #{items.size} (#{high} high, #{medium} medium, #{low} low impact)
      Estimated remediation: #{effort[:total_hours]} hours
      Top impacted items:
      #{top_items}
    PROMPT

    response = Ai::Client.chat(prompt, task_type: :factual, agent_name: "ImpactPredictionSummary")
    response.content
  rescue => e
    Rails.logger.warn "[ImpactPrediction] Summary generation failed: #{e.message}"
    # Fallback to simple string
    "Impact assessment for '#{regulation.title}': #{items.size} items affected " \
    "(#{high} high, #{medium} medium, #{low} low impact). " \
    "Estimated remediation effort: #{effort[:total_hours]} hours."
  end
end
