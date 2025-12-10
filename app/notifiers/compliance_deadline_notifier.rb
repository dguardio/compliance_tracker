class ComplianceDeadlineNotifier < ApplicationNotifier
  deliver_by :database
  deliver_by :email, mailer: 'ComplianceMailer', method: :deadline_approaching

  param :requirement
  param :days_until_deadline

  def title
    "Compliance Deadline"
  end

  def message
    "The compliance requirement '#{params[:requirement].name}' is due in #{params[:days_until_deadline]} days"
  end

  def url
    Rails.application.routes.url_helpers.organization_compliance_framework_compliance_requirement_path(
      params[:requirement].organization,
      params[:requirement].compliance_framework,
      params[:requirement]
    )
  end
end 