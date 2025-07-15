class DocumentNotificationNotifier < Noticed::Event
  deliver_by :email, mailer: 'DocumentMailer', method: :document_notification

  required_param :document
  required_param :action
  required_param :actor

  def message
    case params[:action]
    when :uploaded
      "#{params[:actor]&.full_name || 'A user'} uploaded a new document: #{params[:document].title}"
    when :updated
      "#{params[:actor]&.full_name || 'A user'} updated document: #{params[:document].title}"
    when :needs_review
      "Document '#{params[:document].title}' needs your review"
    when :approved
      "Document '#{params[:document].title}' has been approved by #{params[:actor]&.full_name}"
    when :rejected
      "Document '#{params[:document].title}' was rejected by #{params[:actor]&.full_name}"
    when :expired
      "Document '#{params[:document].title}' has expired"
    when :expiring_soon
      "Document '#{params[:document].title}' expires in #{params[:document].days_until_expiry} days"
    else
      "Document notification: #{params[:document].title}"
    end
  end

  def title
    case params[:action]
    when :uploaded
      'New Document Uploaded'
    when :updated
      'Document Updated'
    when :needs_review
      'Document Review Required'
    when :approved
      'Document Approved'
    when :rejected
      'Document Rejected'
    when :expired
      'Document Expired'
    when :expiring_soon
      'Document Expiring Soon'
    else
      'Document Notification'
    end
  end

  def url
    Rails.application.routes.url_helpers.organization_document_path(
      params[:document].organization,
      params[:document]
    )
  end
end
