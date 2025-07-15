#!/usr/bin/env ruby

# Test script to verify the permission fix
puts '=== Testing Permission Fix ==='

require_relative 'config/environment'

# Test users that were having issues
test_users = [
  'legal.admin@acme.com',
  'compliance.lead@acme.com',
  'monitoring.manager@acme.com',
  'compliance@techstart.com'
]

test_users.each do |email|
  user = User.find_by(email: email)
  next unless user

  puts "\n--- Testing #{user.email} ---"

  # Test compliance framework permissions
  # For index?, we need to create a policy with a new instance (like the controller does)
  index_policy = ComplianceFrameworkPolicy.new(user, ComplianceFramework.new)
  puts "  Can index?: #{index_policy.index?}"
  
  # For other actions, we test with an existing instance
  compliance_framework = user.organization&.compliance_frameworks&.first
  if compliance_framework
    policy = ComplianceFrameworkPolicy.new(user, compliance_framework)
    puts "  Can show?: #{policy.show?}"
    puts "  Can create?: #{policy.create?}"
    puts "  Can update?: #{policy.update?}"
    puts "  Can destroy?: #{policy.destroy?}"
  end

  # Test permission management
  policy = PermissionPolicy.new(user, Permission.new)
  puts "  Can index permissions?: #{policy.index?}"
  puts "  Can create permissions?: #{policy.create?}"
end

puts "\n=== Test Complete ==="
