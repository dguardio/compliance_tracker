#!/usr/bin/env ruby

# Debug script to check permissions and fix authorization issues
puts '=== Compliance Tracker Permission Debug ==='

# Load Rails environment
require_relative 'config/environment'

puts "\n1. Checking Organizations..."
organizations = Organization.all
puts "Found #{organizations.count} organizations:"
organizations.each do |org|
  puts "  - #{org.name} (ID: #{org.id})"
end

puts "\n2. Checking Users..."
users = User.all
puts "Found #{users.count} users:"
users.each do |user|
  puts "  - #{user.email} (Org: #{user.organization&.name || 'None'})"
end

puts "\n3. Checking Roles..."
roles = Role.all
puts "Found #{roles.count} roles:"
roles.each do |role|
  puts "  - #{role.name} (Org: #{role.organization&.name || 'None'})"
end

puts "\n4. Checking Permissions..."
permissions = Permission.all
puts "Found #{permissions.count} permissions:"
permissions.group_by(&:organization).each do |org, org_permissions|
  puts "  #{org&.name || 'No Org'}: #{org_permissions.count} permissions"
  org_permissions.first(5).each do |perm|
    puts "    - #{perm.name} (#{perm.action} #{perm.resource_type})"
  end
  puts "    ... and #{org_permissions.count - 5} more" if org_permissions.count > 5
end

puts "\n5. Testing Super Admin Permissions..."
super_admin = User.find_by(email: 'admin@complianceapp.com')
if super_admin
  puts "Super Admin found: #{super_admin.email}"
  puts "Organization: #{super_admin.organization&.name || 'None'}"
  puts "Roles: #{super_admin.roles.pluck(:name).join(', ')}"

  # Test compliance permissions
  compliance_framework = ComplianceFramework.first
  if compliance_framework
    puts "\nTesting Compliance Framework permissions..."
    policy = ComplianceFrameworkPolicy.new(super_admin, compliance_framework)
    puts "  Can index?: #{policy.index?}"
    puts "  Can show?: #{policy.show?}"
    puts "  Can create?: #{policy.create?}"
    puts "  Can update?: #{policy.update?}"
    puts "  Can destroy?: #{policy.destroy?}"
  end
else
  puts 'Super Admin not found!'
end

puts "\n6. Testing Organization Admin Permissions..."
org_admin = User.find_by(email: 'admin@acme.com')
if org_admin
  puts "Org Admin found: #{org_admin.email}"
  puts "Organization: #{org_admin.organization&.name || 'None'}"
  puts "Roles: #{org_admin.roles.pluck(:name).join(', ')}"

  # Test compliance permissions
  compliance_framework = org_admin.organization&.compliance_frameworks&.first
  if compliance_framework
    puts "\nTesting Compliance Framework permissions..."
    policy = ComplianceFrameworkPolicy.new(org_admin, compliance_framework)
    puts "  Can index?: #{policy.index?}"
    puts "  Can show?: #{policy.show?}"
    puts "  Can create?: #{policy.create?}"
    puts "  Can update?: #{policy.update?}"
    puts "  Can destroy?: #{policy.destroy?}"
  end
else
  puts 'Org Admin not found!'
end

puts "\n7. Checking for missing permissions..."
puts 'Creating basic permissions if missing...'

organizations.each do |org|
  # Find or create super admin for this org
  super_admin = User.find_by(email: 'admin@complianceapp.com')
  org_admin = org.users.find_by(email: "admin@#{org.slug}.com")

  if super_admin
    # Ensure super admin has full permissions
    Permission.find_or_create_by(
      organization: org,
      name: 'Super Admin - Full Compliance Access',
      action: 'manage',
      resource_type: 'ComplianceFramework',
      resource: nil,
      grantee: super_admin
    )

    Permission.find_or_create_by(
      organization: org,
      name: 'Super Admin - Full Compliance Requirements Access',
      action: 'manage',
      resource_type: 'ComplianceRequirement',
      resource: nil,
      grantee: super_admin
    )

    Permission.find_or_create_by(
      organization: org,
      name: 'Super Admin - Full Compliance Controls Access',
      action: 'manage',
      resource_type: 'ComplianceControl',
      resource: nil,
      grantee: super_admin
    )

    puts "Created super admin permissions for #{org.name}"
  end

  next unless org_admin

  # Ensure org admin has full permissions
  Permission.find_or_create_by(
    organization: org,
    name: 'Org Admin - Manage Compliance Frameworks',
    action: 'manage',
    resource_type: 'ComplianceFramework',
    resource: nil,
    grantee: org_admin
  )

  Permission.find_or_create_by(
    organization: org,
    name: 'Org Admin - Manage Compliance Requirements',
    action: 'manage',
    resource_type: 'ComplianceRequirement',
    resource: nil,
    grantee: org_admin
  )

  Permission.find_or_create_by(
    organization: org,
    name: 'Org Admin - Manage Compliance Controls',
    action: 'manage',
    resource_type: 'ComplianceControl',
    resource: nil,
    grantee: org_admin
  )

  puts "Created org admin permissions for #{org.name}"
end

puts "\n8. Final permission count..."
puts "Total permissions: #{Permission.count}"

puts "\n=== Debug Complete ==="
puts "Try accessing the application now. If issues persist, run 'rails db:seed' to recreate all permissions."
