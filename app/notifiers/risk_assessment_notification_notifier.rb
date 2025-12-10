# To deliver this notification:
#
# RiskAssessmentNotificationNotifier.with(record: @post, message: "New post").deliver(User.all)

class RiskAssessmentNotificationNotifier < ApplicationNotifier
  deliver_by :database
  deliver_by :email, mailer: "RiskAssessmentMailer", method: :risk_assessment_notification, if: :email_enabled?

  param :risk_assessment
  param :action # :created, :updated, :assigned, :overdue, :high_risk
  param :actor, optional: true

  def title
    "Risk Assessment Update"
  end

  def message
    ra = params[:risk_assessment]
    case params[:action].to_sym
    when :created
      "A new risk assessment '#{ra.name}' was created."
    when :updated
      "Risk assessment '#{ra.name}' was updated."
    when :assigned
      "You have been assigned to risk assessment '#{ra.name}'."
    when :overdue
      "Risk assessment '#{ra.name}' is overdue!"
    when :high_risk
      "Risk assessment '#{ra.name}' is flagged as HIGH RISK!"
    else
      "Risk assessment '#{ra.name}' notification."
    end
  end

  def url
    ra = params[:risk_assessment]
    Rails.application.routes.url_helpers.organization_risk_assessment_path(ra.organization, ra)
  end

  def email_enabled?
    # Add logic if you want to enable/disable email delivery
    true
  end
end
