class RiskAssessmentMailer < ApplicationMailer
  def risk_assessment_notification
    @notification = params[:notification]
    @risk_assessment = @notification.params[:risk_assessment]
    @action = @notification.params[:action]
    @actor = @notification.params[:actor]

    mail(
      to: @notification.recipient.email,
      subject: "Risk Assessment #{@action.titleize}: #{@risk_assessment.name}"
    )
  end
end
