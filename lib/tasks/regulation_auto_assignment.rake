namespace :regulations do
  desc 'Test regulation auto-assignment system'
  task test_auto_assignment: :environment do
    puts 'Testing Regulation Auto-assignment System...'
    puts '=' * 50

    # Check if we have organizations and regulations
    org_count = Organization.count
    reg_count = Regulation.count

    puts "Organizations: #{org_count}"
    puts "Regulations: #{reg_count}"

    if org_count == 0 || reg_count == 0
      puts '❌ Need organizations and regulations to test auto-assignment'
      puts "Run 'rails db:seed' first to create sample data"
      exit 1
    end

    # Test bulk auto-assignment
    puts "\n🔄 Running bulk auto-assignment..."
    service = RegulationAutoAssignmentService.new

    before_count = OrganizationRegulation.count
    service.bulk_auto_assignment
    after_count = OrganizationRegulation.count

    puts "Assignments created: #{after_count - before_count}"
    puts "Total assignments: #{after_count}"

    # Show results by organization
    puts "\n📊 Assignment Results by Organization:"
    puts '-' * 40

    Organization.includes(:organization_regulations).each do |org|
      assignments = org.organization_regulations
      puts "#{org.name}:"
      puts "  - Total assignments: #{assignments.count}"
      puts "  - Active: #{assignments.active.count}"
      puts "  - Pending: #{assignments.pending.count}"
      puts "  - High priority (6+): #{assignments.where('priority >= ?', 6).count}"

      if assignments.any?
        puts '  - Sample assignments:'
        assignments.limit(3).each do |assignment|
          puts "    • #{assignment.regulation.title} (Priority: #{assignment.priority}, Status: #{assignment.status})"
        end
      end
      puts
    end

    puts '✅ Auto-assignment test completed!'
  end

  desc 'Clear all regulation assignments'
  task clear_assignments: :environment do
    puts 'Clearing all regulation assignments...'
    count = OrganizationRegulation.count
    OrganizationRegulation.destroy_all
    puts "Cleared #{count} assignments"
  end

  desc 'Run auto-assignment for specific organization'
  task :assign_to_org, [:org_id] => :environment do |task, args|
    org_id = args[:org_id]

    if org_id.blank?
      puts 'Usage: rails regulations:assign_to_org[organization_id]'
      exit 1
    end

    organization = Organization.find(org_id)
    puts "Running auto-assignment for: #{organization.name}"

    service = RegulationAutoAssignmentService.new
    service.assign_to_organization(organization)

    assignments = organization.organization_regulations
    puts "Created #{assignments.count} assignments"
  end
end
