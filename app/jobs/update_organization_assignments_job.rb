# frozen_string_literal: true

# Job to update regulation assignments for an organization after its
# compliance profile has changed.
class UpdateOrganizationAssignmentsJob < ApplicationJob
  queue_as :default

  def perform(organization_id)
    organization = Organization.find_by(id: organization_id)
    unless organization
      Rails.logger.warn "UpdateOrganizationAssignmentsJob could not find Organization with ID #{organization_id}"
      return
    end

    Rails.logger.info "Starting to update regulation assignments for Organization ID: #{organization.id}"
    newly_assigned_regulations = RegulationAutoAssignmentService.new.update_organization_assignments(organization)
    Rails.logger.info "Finished updating regulation assignments for Organization ID: #{organization.id}. Found #{newly_assigned_regulations.count} new assignments."

    # Deliver notifications for each newly assigned regulation
    if newly_assigned_regulations.any?
      recipients = organization.users
      newly_assigned_regulations.each do |regulation|
        NewRegulationAssignedNotifier.with(regulation: regulation, organization: organization).deliver(recipients)
      end
      Rails.logger.info "Enqueued notifications for #{newly_assigned_regulations.count} new regulations to #{recipients.count} users in #{organization.name}."
    end
  end
