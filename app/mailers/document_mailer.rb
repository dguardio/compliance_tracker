class DocumentMailer < ApplicationMailer
  def document_notification
    @notification = params[:notification]
    @document = @notification.params[:document]
    @action = @notification.params[:action]
    @actor = @notification.params[:actor]
    @recipient = @notification.recipient

    mail(
      to: @recipient.email,
      subject: @notification.title
    )
  end

  def document_review_request
    @document = params[:document]
    @recipient = params[:recipient]
    @uploader = @document.uploaded_by

    mail(
      to: @recipient.email,
      subject: "Document Review Required: #{@document.title}"
    )
  end

  def document_approved
    @document = params[:document]
    @recipient = params[:recipient]
    @approver = params[:approver]

    mail(
      to: @recipient.email,
      subject: "Document Approved: #{@document.title}"
    )
  end

  def document_expiring_soon
    @document = params[:document]
    @recipient = params[:recipient]
    @days_until_expiry = @document.days_until_expiry

    mail(
      to: @recipient.email,
      subject: "Document Expiring Soon: #{@document.title}"
    )
  end
end
