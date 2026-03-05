module ComplianceExportable
  extend ActiveSupport::Concern

  private

  def require_export_feature!
    require_feature!(:compliance_exports)
  end

  def export_frameworks_csv(organization)
    frameworks = organization.compliance_frameworks.includes(
      compliance_requirements: :compliance_controls
    )

    CSV.generate(headers: true) do |csv|
      csv << ["Framework", "Status", "Version", "Requirements Count", "Controls Count", "Created At"]
      frameworks.each do |framework|
        csv << [
          framework.name,
          framework.status,
          framework.version,
          framework.compliance_requirements.count,
          framework.compliance_requirements.sum { |r| r.compliance_controls.count },
          framework.created_at.strftime("%Y-%m-%d")
        ]
      end
    end
  end

  def export_requirements_csv(organization, framework = nil)
    requirements = framework ? framework.compliance_requirements : organization.compliance_requirements
    requirements = requirements.includes(:compliance_framework, :compliance_controls)

    CSV.generate(headers: true) do |csv|
      csv << ["Framework", "Requirement", "Code", "Type", "Priority", "Risk Level", "Status", "Controls Count"]
      requirements.each do |req|
        csv << [
          req.compliance_framework&.name,
          req.name,
          req.code,
          req.requirement_type,
          req.priority,
          req.risk_level,
          req.status,
          req.compliance_controls.count
        ]
      end
    end
  end

  def export_controls_csv(organization, framework = nil)
    controls = if framework
                 ComplianceControl.joins(:compliance_requirement)
                                  .where(compliance_requirements: { compliance_framework_id: framework.id })
               else
                 organization.compliance_controls
               end
    controls = controls.includes(compliance_requirement: :compliance_framework)

    CSV.generate(headers: true) do |csv|
      csv << ["Framework", "Requirement", "Control", "Type", "Effectiveness", "Status", "Assignee", "Due Date"]
      controls.each do |control|
        csv << [
          control.compliance_requirement&.compliance_framework&.name,
          control.compliance_requirement&.name,
          control.name,
          control.control_type,
          control.effectiveness,
          control.status,
          control.assignee&.full_name,
          control.due_date&.strftime("%Y-%m-%d")
        ]
      end
    end
  end

  def export_risk_assessments_csv(organization)
    assessments = organization.risk_assessments.includes(
      :assigned_to, :created_by, :compliance_framework,
      :compliance_requirement, :compliance_control
    )

    CSV.generate(headers: true) do |csv|
      csv << ["Name", "Framework", "Requirement", "Control", "Likelihood", "Impact", "Risk Score", "Risk Level", "Status", "Assigned To", "Assessment Date", "Next Review"]
      assessments.each do |ra|
        csv << [
          ra.name,
          ra.compliance_framework&.name,
          ra.compliance_requirement&.name,
          ra.compliance_control&.name,
          ra.likelihood,
          ra.impact,
          ra.risk_score,
          ra.risk_level,
          ra.status,
          ra.assigned_to&.full_name,
          ra.assessment_date&.strftime("%Y-%m-%d"),
          ra.next_review_date&.strftime("%Y-%m-%d")
        ]
      end
    end
  end
end
