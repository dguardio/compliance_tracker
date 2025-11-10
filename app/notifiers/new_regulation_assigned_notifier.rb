class NewRegulationAssignedNotifier < ApplicationNotifier
  # Delivery methods
  deliver_by :database
  # deliver_by :email, mailer: "UserMailer" # Can be enabled later

  # Required parameters
  param :regulation
  param :organization

  # Helper methods for rendering
  def message
    "A new regulation, '#{regulation.title}', has been assigned to your organization."
  end

  def url
    # This route doesn't exist yet, but is the logical target for a user to view the regulation.
    # Fallback to the organization's main page to prevent errors.
    Rails.application.routes.url_helpers.organization_regulation_path(organization, regulation)
  rescue ActionController::UrlGenerationError
    Rails.application.routes.url_helpers.organization_path(organization)
  end
end
