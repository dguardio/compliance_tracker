class ComplianceDeadlineJob < ApplicationJob
  queue_as :default

  def perform
    # Find requirements with deadlines approaching (within 30 days)
    ComplianceRequirement.joins(:compliance_framework)
                         .where('next_review_date BETWEEN ? AND ?', Date.current, 30.days.from_now)
                         .includes(:organization, :compliance_framework).each do |requirement|
      days_until_deadline = (requirement.next_review_date - Date.current).to_i

      # Send notification to assigned users or organization admins
      recipients = get_deadline_recipients(requirement)

      recipients.each do |recipient|
        ComplianceDeadlineNotifier.with(
          requirement: requirement,
          days_until_deadline: days_until_deadline
        ).deliver_later(recipient)
      end
    end
  end

  private

  def get_deadline_recipients(requirement)
    recipients = []

    # Add organization admins
    recipients += requirement.organization.users.joins(:roles)
                             .where(roles: { name: %w[org_admin super_admin] })

    # Add users assigned to this requirement (if there's an assignment mechanism)
    # This would depend on your assignment implementation

    recipients.uniq
  end
end
