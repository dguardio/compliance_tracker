#!/usr/bin/env ruby

# Script to clean up problematic API permissions
puts '=== Cleaning up API permissions ==='

require_relative 'config/environment'

# Find and delete any permissions with resource_type 'Api'
api_permissions = Permission.where(resource_type: 'Api')
puts "Found #{api_permissions.count} API permissions to remove:"

api_permissions.each do |perm|
  puts "  - #{perm.name} (ID: #{perm.id})"
end

if api_permissions.any?
  api_permissions.destroy_all
  puts 'Removed all API permissions successfully!'
else
  puts 'No API permissions found to remove.'
end

puts '=== Cleanup complete ==='
