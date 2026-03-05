class HarmonizationService
  def initialize(organization)
    @organization = organization
  end

  # Build cross-reference matrix: Control × Framework grid
  def generate_matrix(framework_ids)
    frameworks = ComplianceFramework.where(id: framework_ids)
    return { frameworks: [], matrix: [], summary: {} } if frameworks.empty?

    controls = ComplianceControl.joins(:compliance_requirement)
                  .where(compliance_requirements: { compliance_framework_id: framework_ids })
                  .includes(compliance_requirement: :compliance_framework)
                  .distinct

    # Build matrix: for each control, which frameworks does it cover?
    matrix = controls.map do |control|
      covered_frameworks = [control.compliance_requirement.compliance_framework_id]

      # Check for mappings to requirements in other frameworks
      mapped_requirement_ids = FrameworkMapping.where(organization: @organization)
                                               .for_requirement(control.compliance_requirement_id)
                                               .pluck(:source_requirement_id, :target_requirement_id)
                                               .flatten
                                               .uniq

      mapped_fw_ids = ComplianceRequirement.where(id: mapped_requirement_ids)
                                            .pluck(:compliance_framework_id)
                                            .uniq

      covered_frameworks = (covered_frameworks + mapped_fw_ids).uniq

      {
        control: control,
        framework_coverage: framework_ids.map { |fw_id| { framework_id: fw_id, covered: covered_frameworks.include?(fw_id) } },
        coverage_count: covered_frameworks.count { |fw_id| framework_ids.include?(fw_id) },
        multi_framework: covered_frameworks.count { |fw_id| framework_ids.include?(fw_id) } > 1
      }
    end

    # Summary stats
    total_controls = matrix.size
    multi_framework_controls = matrix.count { |m| m[:multi_framework] }

    {
      frameworks: frameworks,
      matrix: matrix.sort_by { |m| -m[:coverage_count] },
      summary: {
        total_controls: total_controls,
        multi_framework: multi_framework_controls,
        single_framework: total_controls - multi_framework_controls,
        harmonization_rate: total_controls > 0 ? ((multi_framework_controls.to_f / total_controls) * 100).round(1) : 0
      }
    }
  end

  # Analyze gap when adopting a new framework
  def analyze_delta(new_framework_id)
    new_framework = ComplianceFramework.find(new_framework_id)
    new_requirements = new_framework.compliance_requirements

    existing_framework_ids = @organization.compliance_frameworks
                                          .where.not(id: new_framework_id)
                                          .pluck(:id)

    existing_controls = ComplianceControl.joins(:compliance_requirement)
                          .where(compliance_requirements: { compliance_framework_id: existing_framework_ids })
                          .includes(:compliance_requirement)

    # For each new requirement, check if any existing control covers it
    gap_analysis = new_requirements.map do |requirement|
      # Check direct mappings
      mappings = FrameworkMapping.where(organization: @organization, target_requirement_id: requirement.id)
                                 .or(FrameworkMapping.where(organization: @organization, source_requirement_id: requirement.id))
                                 .includes(:source_requirement, :target_requirement)

      covering_controls = if mappings.any?
        mapped_req_ids = mappings.pluck(:source_requirement_id, :target_requirement_id).flatten.uniq - [requirement.id]
        ComplianceControl.where(compliance_requirement_id: mapped_req_ids)
      else
        ComplianceControl.none
      end

      {
        requirement: requirement,
        covered: covering_controls.any?,
        covering_controls: covering_controls.to_a,
        mapping_count: mappings.count,
        best_confidence: mappings.maximum(:confidence) || 0
      }
    end

    covered = gap_analysis.count { |g| g[:covered] }
    total = gap_analysis.size

    {
      framework: new_framework,
      gap_analysis: gap_analysis.sort_by { |g| g[:covered] ? 1 : 0 },
      coverage_percentage: total > 0 ? ((covered.to_f / total) * 100).round(1) : 0,
      gap_count: total - covered,
      covered_count: covered,
      total_requirements: total
    }
  end

  # Detect overlap: controls that satisfy requirements in 2+ frameworks
  def detect_overlap
    framework_ids = @organization.compliance_frameworks.pluck(:id)
    return [] if framework_ids.size < 2

    result = generate_matrix(framework_ids)
    result[:matrix].select { |m| m[:multi_framework] }
  end

  # AI-suggest extensions: "extend control X to also cover requirement Y"
  def suggest_extensions
    framework_ids = @organization.compliance_frameworks.pluck(:id)
    return [] if framework_ids.size < 2

    # Find uncovered requirements
    all_requirements = ComplianceRequirement.where(compliance_framework_id: framework_ids)
    covered_requirement_ids = ComplianceControl.joins(:compliance_requirement)
                                               .where(compliance_requirements: { compliance_framework_id: framework_ids })
                                               .pluck(:compliance_requirement_id)

    uncovered = all_requirements.where.not(id: covered_requirement_ids)

    # For each uncovered requirement, find the most similar existing control
    suggestions = uncovered.limit(20).map do |requirement|
      closest_control = find_closest_control(requirement, framework_ids)
      next unless closest_control

      {
        requirement: requirement,
        suggested_control: closest_control[:control],
        similarity_reason: closest_control[:reason],
        confidence: closest_control[:confidence]
      }
    end.compact

    suggestions.sort_by { |s| -s[:confidence] }
  end

  private

  def find_closest_control(requirement, framework_ids)
    req_text = [requirement.title, requirement.description].compact.join(' ')
    req_embedding = Ai::Client.embed(req_text, agent_name: "HarmonizationService")

    best_match = nil
    best_score = 0

    ComplianceControl.joins(:compliance_requirement)
                      .where(compliance_requirements: { compliance_framework_id: framework_ids })
                      .where.not(compliance_requirement_id: requirement.id)
                      .includes(:compliance_requirement)
                      .limit(100)
                      .each do |control|
      ctrl_text = [control.name, control.description].compact.join(' ')

      if req_embedding.present?
        ctrl_embedding = Ai::Client.embed(ctrl_text, agent_name: "HarmonizationService")
        if ctrl_embedding.present?
          dot = req_embedding.zip(ctrl_embedding).sum { |a, b| a * b }
          mag_r = Math.sqrt(req_embedding.sum { |x| x**2 })
          mag_c = Math.sqrt(ctrl_embedding.sum { |x| x**2 })
          score = mag_r > 0 && mag_c > 0 ? (dot / (mag_r * mag_c)).clamp(0, 1) : 0
        else
          score = keyword_score(req_text, ctrl_text)
        end
      else
        score = keyword_score(req_text, ctrl_text)
      end

      if score > best_score && score > 0.2
        best_score = score
        best_match = { control: control, score: score, ctrl_text: ctrl_text }
      end
    end

    return nil unless best_match

    # Use LLM to explain the mapping rationale
    reason = generate_mapping_rationale(req_text, best_match[:ctrl_text], requirement, best_match[:control])

    {
      control: best_match[:control],
      reason: reason,
      confidence: (best_match[:score] * 100).round(1)
    }
  end

  def generate_mapping_rationale(req_text, ctrl_text, requirement, control)
    prompt = <<~PROMPT
      Explain in ONE sentence why the following compliance control could satisfy the given requirement.
      Be specific about the overlap.

      Requirement (#{requirement.compliance_framework&.name}): #{req_text.truncate(300)}
      Control: #{ctrl_text.truncate(300)}
    PROMPT

    response = Ai::Client.chat(prompt, task_type: :factual, agent_name: "HarmonizationRationale")
    response.content.strip
  rescue => e
    Rails.logger.warn "[HarmonizationService] Rationale generation failed: #{e.message}"
    "Similar scope and objectives based on semantic similarity analysis."
  end

  def keyword_score(text_a, text_b)
    words_a = text_a.downcase.split(/\W+/).uniq.reject { |w| w.length < 3 }
    words_b = text_b.downcase.split(/\W+/).uniq.reject { |w| w.length < 3 }
    return 0 if words_a.empty? || words_b.empty?

    overlap = (words_a & words_b).size
    overlap.to_f / [words_a.size, words_b.size].min
  end
end
