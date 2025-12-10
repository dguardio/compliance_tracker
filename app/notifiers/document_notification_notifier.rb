class DocumentNotificationNotifier < ApplicationNotifier
  deliver_by :email, mailer: 'DocumentMailer', method: :document_notification

  required_param :document
  required_param :action

  def title
    case params[:action].to_sym
    when :uploaded
      "Document Uploaded"
    when :updated
      "Document Updated"
    when :needs_review
      "Review Requested"
    when :approved
      "Document Approved"
    when :rejected
      "Document Rejected"
    when :expired
      "Document Expired"
    when :expiring_soon
      "Document Expiring Soon"
    else
      "Document Notification"
    end
  end


  def message
    doc = params[:document]
    actor = params[:actor]
    case params[:action].to_sym
    when :uploaded
      "#{actor&.full_name || 'A user'} uploaded a new document: #{doc.title}"
    when :updated
      "#{actor&.full_name || 'A user'} updated document: #{doc.title}"
    when :needs_review
      "Document '#{doc.title}' needs your review"
    when :approved
      "Document '#{doc.title}' has been approved by #{actor&.full_name}"
    when :rejected
      "Document '#{doc.title}' was rejected by #{actor&.full_name}"
    when :expired
      "Document '#{doc.title}' has expired"
    when :expiring_soon
      "Document '#{doc.title}' expires in #{doc.days_until_expiry} days"
    else
      "Document notification: #{doc.title}"
    end
  end

  def url
    doc = params[:document]
    if doc.organization
      Rails.application.routes.url_helpers.organization_document_path(doc.organization, doc)
    elsif doc.regulation
      Rails.application.routes.url_helpers.admin_regulation_path(doc.regulation)
    else
      Rails.application.routes.url_helpers.dashboard_path
    end
  end
end 