# frozen_string_literal: true

class RegulationReviewNotifier < Noticed::Base
  deliver_by :database # Stores notifications in the database
  deliver_by :email, mailer: 'RegulationReviewMailer', if: :email_notifications_enabled? # Sends email if enabled

  param :regulation_review
  param :new_state

  def title
    "Regulation Review"
  end

  # Define the message for the notification
  def message
    @regulation_review = params[:regulation_review]
    @new_state = params[:new_state]
    "Regulation '#{@regulation_review.organization_regulation.regulation.title}' requires your review for the '#{@new_state}' step."
  end

  # Define the URL for the notification
  def url
    regulation_review_path(params[:regulation_review])
  end

  # Check if email notifications are enabled for the recipient
  def email_notifications_enabled?
    recipient.notification_enabled?(:regulation_review_email)
  end
end
