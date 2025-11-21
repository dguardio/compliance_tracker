# frozen_string_literal: true

class ControlAssignedNotifier < Noticed::Base
  deliver_by :database
  deliver_by :email, mailer: 'ControlAssignedMailer', if: :email_notifications_enabled?

  param :compliance_control
  param :assigned_by

  def message
    @control = params[:compliance_control]
    @assigner = params[:assigned_by]
    "Task '#{@control.name}' has been assigned to you by #{@assigner.full_name}."
  end

  def url
    organization_compliance_framework_compliance_requirement_compliance_control_path(
      @control.organization,
      @control.compliance_framework,
      @control.compliance_requirement,
      @control
    )
  end

  def email_notifications_enabled?
    recipient.notification_enabled?(:control_assigned_email)
  end
end
