#!/usr/bin/env ruby

# Detailed debug script for specific users with permission issues
puts '=== Detailed Permission Debug for Problem Users ==='

require_relative 'config/environment'

# Test users that were having issues
problem_users = [
  'legal.admin@acme.com',
  'compliance.lead@acme.com',
  'monitoring.manager@acme.com',
  'compliance@techstart.com'
]

problem_users.each do |email|
  user = User.find_by(email: email)
  next unless user

  puts "\n" + '=' * 60
  puts "DETAILED DEBUG: #{user.email}"
  puts '=' * 60

  puts "Organization: #{user.organization.name}"
  puts "Roles: #{user.roles.pluck(:name).join(', ')}"

  # Check compliance framework permissions specifically
  puts "\n--- Compliance Framework Permissions ---"

  # Direct user permissions for ComplianceFramework
  direct_perms = user.organization.permissions
                     .for_user(user)
                     .for_resource_type('ComplianceFramework')

  puts "Direct user permissions for ComplianceFramework: #{direct_perms.count}"
  direct_perms.each do |perm|
    puts "  - #{perm.name} (#{perm.action}) - can_perform?: #{perm.can_perform?(user)}"
  end

  # Role-based permissions for ComplianceFramework
  puts "\nRole-based permissions for ComplianceFramework:"
  user.roles.each do |role|
    role_perms = user.organization.permissions
                     .for_role(role)
                     .for_resource_type('ComplianceFramework')
    puts "  Role '#{role.name}': #{role_perms.count} permissions"
    role_perms.each do |perm|
      puts "    - #{perm.name} (#{perm.action}) - can_perform?: #{perm.can_perform?(user)}"
    end
  end

  # Test Permission.user_has_permission? for different actions
  puts "\n--- Testing Permission.user_has_permission? ---"
  actions = %w[read create update destroy manage]
  actions.each do |action|
    result = Permission.user_has_permission?(user, action, 'ComplianceFramework')
    puts "  #{action} ComplianceFramework: #{result}"
  end

  # Test the policy directly
  puts "\n--- Testing Policy Directly ---"
  compliance_framework = user.organization.compliance_frameworks.first
  if compliance_framework
    policy = ComplianceFrameworkPolicy.new(user, compliance_framework)

    puts 'Policy instance variables:'
    puts "  user: #{policy.user.email}"
    puts "  record: #{policy.record.class.name} (ID: #{policy.record.id})"

    puts "\nPolicy method results:"
    puts "  index?: #{policy.index?}"
    puts "  show?: #{policy.show?}"
    puts "  create?: #{policy.create?}"
    puts "  update?: #{policy.update?}"
    puts "  destroy?: #{policy.destroy?}"

    # Test the can? method directly
    puts "\nDirect can? method tests:"
    puts "  can?(:read, 'ComplianceFramework'): #{policy.can?(:read, 'ComplianceFramework')}"
    puts "  can?(:manage, 'ComplianceFramework'): #{policy.can?(:manage, 'ComplianceFramework')}"
    puts "  can?(:read, 'ComplianceFramework', compliance_framework): #{policy.can?(:read, 'ComplianceFramework',
                                                                                    compliance_framework)}"
  end

  # Check if user has any permissions at all
  puts "\n--- All User Permissions Summary ---"
  all_perms = user.organization.permissions.for_user(user)
  puts "Total direct permissions: #{all_perms.count}"

  role_perms = []
  user.roles.each do |role|
    role_perms += user.organization.permissions.for_role(role)
  end
  puts "Total role-based permissions: #{role_perms.count}"

  puts "\nPermission actions breakdown:"
  all_actions = (all_perms.pluck(:action) + role_perms.pluck(:action)).uniq.sort
  all_actions.each do |action|
    direct_count = all_perms.where(action: action).count
    role_count = role_perms.select { |p| p.action == action }.count
    puts "  #{action}: #{direct_count} direct, #{role_count} role-based"
  end
end

puts "\n" + '=' * 60
puts 'DEBUG COMPLETE'
puts '=' * 60
