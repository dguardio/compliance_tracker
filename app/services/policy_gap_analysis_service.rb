class PolicyGapAnalysisService
  def initialize(organization)
    @organization = organization
  end

  # Analyze policy coverage for a specific framework
  def analyze(framework)
    requirements = framework.compliance_requirements.includes(:compliance_controls)

    # For each requirement, check if there are linked policies
    gap_analysis = requirements.map do |requirement|
      # Check direct policy links
      policy_links = PolicyLink.where(
        linkable_type: 'ComplianceRequirement',
        linkable_id: requirement.id
      ).includes(:policy)

      # Also check framework-level policy links
      fw_policy_links = PolicyLink.where(
        linkable_type: 'ComplianceFramework',
        linkable_id: framework.id
      ).includes(:policy)

      all_policies = (policy_links.map(&:policy) + fw_policy_links.map(&:policy)).uniq

      # Check if controls have descriptions/procedures
      controls = requirement.compliance_controls
      has_controls = controls.any?
      has_implemented_controls = controls.where(status: :implemented).any?

      {
        requirement: requirement,
        covered: all_policies.any?,
        policies: all_policies,
        policy_count: all_policies.size,
        has_controls: has_controls,
        has_implemented_controls: has_implemented_controls,
        coverage_strength: calculate_coverage_strength(all_policies, has_controls, has_implemented_controls)
      }
    end

    covered = gap_analysis.count { |g| g[:covered] }
    total = gap_analysis.size

    {
      framework: framework,
      gap_analysis: gap_analysis.sort_by { |g| g[:covered] ? 1 : 0 },
      coverage_percentage: total > 0 ? ((covered.to_f / total) * 100).round(1) : 0,
      gap_count: total - covered,
      covered_count: covered,
      total_requirements: total
    }
  end

  # Coverage percentage for a specific framework
  def coverage_percentage(framework)
    result = analyze(framework)
    result[:coverage_percentage]
  end

  # Summary for all frameworks in the org
  def all_frameworks_summary
    @organization.compliance_frameworks.map do |framework|
      req_count = framework.compliance_requirements.count
      covered = framework.compliance_requirements
                  .joins("LEFT JOIN policy_links ON policy_links.linkable_type = 'ComplianceRequirement' AND policy_links.linkable_id = compliance_requirements.id")
                  .where.not(policy_links: { id: nil })
                  .distinct.count

      {
        framework: framework,
        total_requirements: req_count,
        covered_count: covered,
        gap_count: req_count - covered,
        coverage_percentage: req_count > 0 ? ((covered.to_f / req_count) * 100).round(1) : 0
      }
    end
  end

  # Draft a policy using AI for a specific gap (placeholder for LLM integration)
  def draft_policy(requirement, framework)
    # This generates a policy draft using the existing PolicyWriterAgent or LLM
    # For now, create a structured draft that can be enhanced with AI later
    org_name = @organization.name
    industry = @organization.settings&.dig('industry') || 'Technology'

    {
      title: "#{requirement.title} Policy",
      description: "Policy addressing #{framework.name} requirement: #{requirement.title}",
      body: generate_draft_body(requirement, framework, org_name, industry),
      requirement: requirement,
      framework: framework,
      status: 'draft'
    }
  end

  private

  def calculate_coverage_strength(policies, has_controls, has_implemented)
    return :strong if policies.size >= 2 && has_implemented
    return :good if policies.any? && has_controls
    return :partial if policies.any? || has_controls
    :gap
  end

  def generate_draft_body(requirement, framework, org_name, industry)
    prompt = <<~PROMPT
      You are a compliance policy expert specializing in #{industry}. 
      Draft a professional, comprehensive policy for the following requirement.

      **Organization**: #{org_name}
      **Framework**: #{framework.name}
      **Requirement**: #{requirement.title}
      **Requirement Description**: #{requirement.description.to_s.truncate(1000)}

      Write a complete policy document in markdown format with these sections:
      1. Purpose
      2. Scope
      3. Policy Statement
      4. Requirements (specific, actionable items)
      5. Roles and Responsibilities
      6. Compliance Monitoring
      7. Review Schedule

      Make it specific to #{industry} and #{framework.name}. 
      Include concrete procedures, not just generic statements.
      Do not include a title heading — it will be added separately.
    PROMPT

    response = Ai::Client.chat(
      prompt,
      task_type: :drafting,
      agent_name: "PolicyGapDrafter",
      temperature: 0.5
    )

    response.content
  rescue => e
    Rails.logger.warn "[PolicyGapAnalysis] AI draft failed: #{e.message}. Using template."
    generate_template_body(requirement, framework, org_name, industry)
  end

  def generate_template_body(requirement, framework, org_name, industry)
    <<~POLICY
      # #{requirement.title} Policy

      ## 1. Purpose
      This policy establishes the requirements for #{requirement.title.downcase} at #{org_name}, 
      in compliance with #{framework.name} requirements.

      ## 2. Scope
      This policy applies to all employees, contractors, and third parties who interact with 
      #{org_name}'s information systems and data.

      ## 3. Policy Statement
      #{org_name} is committed to maintaining compliance with #{framework.name} by implementing 
      appropriate controls and procedures related to #{requirement.title.downcase}.

      ## 4. Requirements
      #{requirement.description.present? ? requirement.description : "Specific requirements as defined by #{framework.name}."}

      ## 5. Roles and Responsibilities
      - **Compliance Officer**: Responsible for overseeing adherence to this policy.
      - **Department Heads**: Responsible for ensuring their teams comply with this policy.
      - **All Employees**: Responsible for understanding and following this policy.

      ## 6. Compliance Monitoring
      Compliance with this policy will be monitored through regular assessments and audits 
      as part of the #{framework.name} compliance program.

      ## 7. Review
      This policy will be reviewed annually or when significant changes occur in the 
      regulatory environment.

      ---
      *This is a template-generated draft. AI generation was unavailable.*
    POLICY
  end
end
