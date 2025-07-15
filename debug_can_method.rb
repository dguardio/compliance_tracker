#!/usr/bin/env ruby

# Debug script to test the can? method directly
puts "=== Debugging can? Method ==="

require_relative 'config/environment'

# Test with a problematic user
user = User.find_by(email: 'legal.admin@acme.com')
puts "Testing user: #{user.email}"

# Create a policy instance
policy = ApplicationPolicy.new(user, ComplianceFramework.new)

puts "\n--- Testing can? method directly ---"

# Test different ways of calling can?
puts "1. can?(:read, 'ComplianceFramework'): #{policy.can?(:read, 'ComplianceFramework')}"
puts "2. can?(:manage, 'ComplianceFramework'): #{policy.can?(:manage, 'ComplianceFramework')}"

# Test with a specific resource
compliance_framework = user.organization.compliance_frameworks.first
if compliance_framework
  puts "3. can?(:read, 'ComplianceFramework', compliance_framework): #{policy.can?(:read, 'ComplianceFramework', compliance_framework)}"
  puts "4. can?(:manage, 'ComplianceFramework', compliance_framework): #{policy.can?(:manage, 'ComplianceFramework', compliance_framework)}"
end

# Test Permission.user_has_permission? directly
puts "\n--- Testing Permission.user_has_permission? directly ---"
puts "1. Permission.user_has_permission?(user, 'read', 'ComplianceFramework'): #{Permission.user_has_permission?(user, 'read', 'ComplianceFramework')}"
puts "2. Permission.user_has_permission?(user, 'manage', 'ComplianceFramework'): #{Permission.user_has_permission?(user, 'manage', 'ComplianceFramework')}"

if compliance_framework
  puts "3. Permission.user_has_permission?(user, 'read', 'ComplianceFramework', compliance_framework): #{Permission.user_has_permission?(user, 'read', 'ComplianceFramework', compliance_framework)}"
  puts "4. Permission.user_has_permission?(user, 'manage', 'ComplianceFramework', compliance_framework): #{Permission.user_has_permission?(user, 'manage', 'ComplianceFramework', compliance_framework)}"
end

# Test the specific permissions this user has
puts "\n--- User's ComplianceFramework Permissions ---"
perms = user.organization.permissions.for_user(user).for_resource_type('ComplianceFramework')
perms.each do |perm|
  puts "Permission: #{perm.name} (#{perm.action})"
  puts "  can_perform? for user: #{perm.can_perform?(user)}"
  puts "  can_perform? for user with resource: #{perm.can_perform?(user, compliance_framework)}" if compliance_framework
end

puts "\n=== Debug Complete ===" 