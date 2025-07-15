class ComplianceMailer < ApplicationMailer
  def requirement_assigned
    @requirement = params[:requirement]
    @assigned_by = params[:assigned_by]
    @assigned_to = params[:assigned_to]
    
    mail(
      to: @assigned_to.email,
      subject: "Compliance requirement assigned: #{@requirement.name}"
    )
  end

  def deadline_approaching
    @requirement = params[:requirement]
    @days_until_deadline = params[:days_until_deadline]
    @recipient = params[:recipient]
    
    mail(
      to: @recipient.email,
      subject: "Compliance deadline approaching: #{@requirement.name}"
    )
  end

  def risk_alert
    @item = params[:item]
    @risk_level = params[:risk_level]
    @alerted_by = params[:alerted_by]
    @recipient = params[:recipient]
    
    mail(
      to: @recipient.email,
      subject: "Risk Alert: #{@item.name}"
    )
  end
end 