namespace :compliance do
  desc 'Send compliance deadline notifications'
  task deadline_notifications: :environment do
    puts 'Running compliance deadline notifications...'
    ComplianceDeadlineJob.perform_now
    puts 'Compliance deadline notifications completed!'
  end

  desc 'Send overdue risk assessment notifications'
  task overdue_risk_notifications: :environment do
    puts 'Checking for overdue risk assessments...'

    overdue_assessments = RiskAssessment.overdue.includes(:assigned_to, :created_by, :organization)

    overdue_assessments.each do |assessment|
      puts "Sending overdue notification for: #{assessment.name}"

      RiskAssessmentNotificationNotifier.with(
        risk_assessment: assessment,
        action: :overdue,
        actor: assessment.created_by
      ).deliver_later(assessment.assigned_to)

      # Also notify organization admins
      assessment.organization.users.joins(:roles).where(roles: { name: %w[org_admin super_admin] }).each do |admin|
        next if admin == assessment.assigned_to

        RiskAssessmentNotificationNotifier.with(
          risk_assessment: assessment,
          action: :overdue,
          actor: assessment.created_by
        ).deliver_later(admin)
      end
    end

    puts 'Overdue risk assessment notifications completed!'
  end
end
