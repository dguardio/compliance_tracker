#!/usr/bin/env ruby

# Debug script to test the index? method specifically
puts "=== Debugging index? Method ==="

require_relative 'config/environment'

# Test with a problematic user
user = User.find_by(email: 'legal.admin@acme.com')
puts "Testing user: #{user.email}"

# Create a policy instance with a new record (like index? does)
policy = ApplicationPolicy.new(user, ComplianceFramework.new)

puts "\n--- Testing index? method ---"
puts "Policy record class: #{policy.record.class.name}"
puts "Policy record: #{policy.record.inspect}"

# Test the index? method
puts "index? result: #{policy.index?}"

# Test what happens in index?
resource_type = policy.record.class.name if policy.record
puts "Resource type: #{resource_type}"

if resource_type
  puts "can?(:read, resource_type) result: #{policy.can?(:read, resource_type)}"
end

# Test Permission.user_has_permission? directly
puts "\n--- Testing Permission.user_has_permission? for index ---"
puts "Permission.user_has_permission?(user, 'read', 'ComplianceFramework'): #{Permission.user_has_permission?(user, 'read', 'ComplianceFramework')}"

# Check if the user has any read permissions for ComplianceFramework
puts "\n--- User's Read Permissions for ComplianceFramework ---"
read_perms = user.organization.permissions.for_user(user).for_action('read').for_resource_type('ComplianceFramework')
puts "Direct read permissions: #{read_perms.count}"
read_perms.each do |perm|
  puts "  - #{perm.name} - can_perform?: #{perm.can_perform?(user)}"
end

# Check role-based read permissions
puts "\nRole-based read permissions:"
user.roles.each do |role|
  role_read_perms = user.organization.permissions.for_role(role).for_action('read').for_resource_type('ComplianceFramework')
  puts "  Role '#{role.name}': #{role_read_perms.count} read permissions"
  role_read_perms.each do |perm|
    puts "    - #{perm.name} - can_perform?: #{perm.can_perform?(user)}"
  end
end

puts "\n=== Debug Complete ===" 