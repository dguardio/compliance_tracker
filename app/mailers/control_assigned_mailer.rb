# frozen_string_literal: true

class ControlAssignedMailer < ApplicationMailer
  def control_assigned
    @user = params[:recipient]
    @control = params[:compliance_control]
    @assigner = params[:assigned_by]

    mail(to: @user.email, subject: "New Task Assigned: #{@control.name}")
  end
end
