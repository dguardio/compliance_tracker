class ComplianceRequirementAssignedNotifier < ApplicationNotifier
  deliver_by :database
  deliver_by :email, mailer: 'ComplianceMailer', method: :requirement_assigned

  param :requirement
  param :assigned_by
  param :assigned_to

  def title
    "Requirement Assigned"
  end

  def message
    "#{params[:assigned_by].full_name} assigned you the compliance requirement '#{params[:requirement].name}'"
  end

  def url
    Rails.application.routes.url_helpers.organization_compliance_framework_compliance_requirement_path(
      params[:requirement].organization,
      params[:requirement].compliance_framework,
      params[:requirement]
    )
  end
end 