class RiskAlertNotifier < ApplicationNotifier
  deliver_by :database
  deliver_by :email, mailer: 'ComplianceMailer', method: :risk_alert

  param :item
  param :risk_level
  param :alerted_by

  def title
    "Risk Alert"
  end

  def message
    "#{params[:alerted_by].full_name} flagged '#{params[:item].name}' as #{params[:risk_level]} risk"
  end

  def url
    case params[:item]
    when ComplianceRequirement
      Rails.application.routes.url_helpers.organization_compliance_framework_compliance_requirement_path(
        params[:item].organization,
        params[:item].compliance_framework,
        params[:item]
      )
    when ComplianceControl
      Rails.application.routes.url_helpers.organization_compliance_framework_compliance_requirement_compliance_control_path(
        params[:item].organization,
        params[:item].compliance_requirement.compliance_framework,
        params[:item].compliance_requirement,
        params[:item]
      )
    else
      Rails.application.routes.url_helpers.dashboard_path
    end
  end
end 