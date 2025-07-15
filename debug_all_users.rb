#!/usr/bin/env ruby

# Comprehensive debug script to check permissions for all users
puts "=== Comprehensive User Permission Debug ==="

# Load Rails environment
require_relative 'config/environment'

puts "\n1. Testing All Users' Permissions..."

users = User.all
users.each do |user|
  puts "\n--- Testing User: #{user.email} ---"
  puts "Organization: #{user.organization&.name || 'None'}"
  puts "Roles: #{user.roles.pluck(:name).join(', ')}"
  puts "Super Admin?: #{user.super_admin?}"
  puts "Org Admin?: #{user.organization_admin?}"
  
  # Test compliance framework permissions
  compliance_framework = user.organization&.compliance_frameworks&.first
  if compliance_framework
    puts "\n  Testing Compliance Framework permissions..."
    policy = ComplianceFrameworkPolicy.new(user, compliance_framework)
    puts "    Can index?: #{policy.index?}"
    puts "    Can show?: #{policy.show?}"
    puts "    Can create?: #{policy.create?}"
    puts "    Can update?: #{policy.update?}"
    puts "    Can destroy?: #{policy.destroy?}"
    
    # Test the underlying can? method
    puts "    Direct can?(:read): #{policy.can?(:read, 'ComplianceFramework')}"
    puts "    Direct can?(:manage): #{policy.can?(:manage, 'ComplianceFramework')}"
  else
    puts "  No compliance frameworks found for this organization"
  end
  
  # Test permission management
  puts "\n  Testing Permission management..."
  policy = PermissionPolicy.new(user, Permission.new)
  puts "    Can index permissions?: #{policy.index?}"
  puts "    Can create permissions?: #{policy.create?}"
  
  # Check user's direct permissions
  puts "\n  User's Direct Permissions:"
  direct_permissions = user.organization&.permissions&.for_user(user) || []
  puts "    Count: #{direct_permissions.count}"
  direct_permissions.first(3).each do |perm|
    puts "    - #{perm.name} (#{perm.action} #{perm.resource_type})"
  end
  puts "    ... and #{direct_permissions.count - 3} more" if direct_permissions.count > 3
  
  # Check user's role-based permissions
  puts "\n  User's Role-Based Permissions:"
  role_permissions = []
  user.roles.each do |role|
    role_perms = user.organization&.permissions&.for_role(role) || []
    role_permissions += role_perms
    puts "    Role '#{role.name}': #{role_perms.count} permissions"
  end
  puts "    Total role permissions: #{role_permissions.count}"
  
  # Test Permission.user_has_permission? directly
  puts "\n  Testing Permission.user_has_permission? directly:"
  if compliance_framework
    puts "    read ComplianceFramework: #{Permission.user_has_permission?(user, 'read', 'ComplianceFramework')}"
    puts "    manage ComplianceFramework: #{Permission.user_has_permission?(user, 'manage', 'ComplianceFramework')}"
  end
  puts "    read Permission: #{Permission.user_has_permission?(user, 'read', 'Permission')}"
  puts "    manage Permission: #{Permission.user_has_permission?(user, 'manage', 'Permission')}"
end

puts "\n2. Checking Permission Distribution..."

organizations = Organization.all
organizations.each do |org|
  puts "\n--- Organization: #{org.name} ---"
  
  # Count permissions by grantee type
  user_permissions = org.permissions.for_grantee_type('User')
  role_permissions = org.permissions.for_grantee_type('Role')
  
  puts "User-based permissions: #{user_permissions.count}"
  puts "Role-based permissions: #{role_permissions.count}"
  
  # Show some examples
  puts "\nUser-based permission examples:"
  user_permissions.first(3).each do |perm|
    grantee = perm.grantee
    puts "  - #{perm.name} → #{grantee.email if grantee.respond_to?(:email) || grantee.name}"
  end
  
  puts "\nRole-based permission examples:"
  role_permissions.first(3).each do |perm|
    grantee = perm.grantee
    puts "  - #{perm.name} → #{grantee.name}"
  end
end

puts "\n3. Testing Specific Permission Issues..."

# Test a specific user that should have permissions
test_user = User.find_by(email: 'compliance.officer@acme.com')
if test_user
  puts "\n--- Testing Compliance Officer ---"
  puts "User: #{test_user.email}"
  puts "Organization: #{test_user.organization.name}"
  puts "Roles: #{test_user.roles.pluck(:name).join(', ')}"
  
  # Check their permissions for compliance frameworks
  compliance_permissions = test_user.organization.permissions
                                   .for_user(test_user)
                                   .for_resource_type('ComplianceFramework')
  
  puts "\nCompliance Framework permissions for this user:"
  compliance_permissions.each do |perm|
    puts "  - #{perm.name} (#{perm.action})"
  end
  
  # Test the permission checking logic
  puts "\nTesting permission logic:"
  compliance_permissions.each do |perm|
    puts "  Permission '#{perm.name}': can_perform? = #{perm.can_perform?(test_user)}"
  end
end

puts "\n4. Checking for Common Issues..."

# Check if any users have no organization
users_without_org = User.where(organization: nil)
if users_without_org.any?
  puts "\n⚠️  Users without organization:"
  users_without_org.each do |user|
    puts "  - #{user.email}"
  end
end

# Check if any permissions have invalid grantees
invalid_permissions = Permission.all.select { |p| p.grantee.nil? }
if invalid_permissions.any?
  puts "\n⚠️  Permissions with invalid grantees:"
  invalid_permissions.first(5).each do |perm|
    puts "  - #{perm.name} (grantee_id: #{perm.grantee_id}, grantee_type: #{perm.grantee_type})"
  end
end

# Check if any permissions have organization mismatches
org_mismatches = Permission.all.select { |p| p.organization && p.grantee && p.grantee.respond_to?(:organization) && p.grantee.organization != p.organization }
if org_mismatches.any?
  puts "\n⚠️  Permissions with organization mismatches:"
  org_mismatches.first(5).each do |perm|
    puts "  - #{perm.name} (perm org: #{perm.organization.name}, grantee org: #{perm.grantee.organization&.name})"
  end
end

puts "\n=== Debug Complete ==="
puts "\nRecommendations:"
puts "1. If super admins and org admins work now, the fix was successful"
puts "2. For other users, check if they have the correct roles assigned"
puts "3. Check if permissions are assigned to the correct users/roles"
puts "4. Verify that all users have an organization assigned"
puts "5. Run 'rails db:seed' if permissions are missing" 