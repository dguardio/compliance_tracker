# frozen_string_literal: true

# Job to assign a newly processed regulation to all matching organizations.
class AssignNewRegulationJob < ApplicationJob
  queue_as :default

  def perform(regulation_id)
    regulation = Regulation.find_by(id: regulation_id)
    unless regulation
      Rails.logger.warn "AssignNewRegulationJob could not find Regulation with ID #{regulation_id}"
      return
    end

    Rails.logger.info "Starting assignment for new Regulation ID: #{regulation.id}"
    assigned_orgs = RegulationAutoAssignmentService.new.process_new_regulation(regulation)
    Rails.logger.info "Finished assignment for new Regulation ID: #{regulation.id} to #{assigned_orgs.count} organizations."

    # Deliver notifications
    assigned_orgs.each do |organization|
      # Notifying all users in the organization. This could be refined to target specific roles.
      recipients = organization.users
      NewRegulationAssignedNotifier.with(regulation: regulation, organization: organization).deliver(recipients)
      Rails.logger.info "Enqueued notifications for #{recipients.count} users in #{organization.name}."
    end
  end
end
