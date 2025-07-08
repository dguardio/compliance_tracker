# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts 'Clearing existing data...'
Permission.destroy_all
User.destroy_all
Role.destroy_all
Unit.destroy_all
Team.destroy_all
Department.destroy_all
Organization.destroy_all

# Helper method to create permissions
def create_permission(organization, name, action, resource_type, resource, grantee, conditions = {})
  puts "Creating permission: #{name}"
  puts "  resource_type: #{resource_type.inspect}"
  puts "  resource: #{resource.inspect}"
  puts "  grantee: #{grantee.inspect}"

  permission = Permission.create!(
    organization: organization,
    name: name,
    action: action,
    resource_type: resource_type,
    resource_id: resource&.id,
    grantee_type: grantee.class.name,
    grantee_id: grantee.id,
    conditions: conditions
  )

  puts "  Created successfully: #{permission.id}"
  permission
end

# Create Organizations
puts 'Creating organizations...'
acme_corp = Organization.create!(
  name: 'Acme Corporation',
  slug: 'acme-corp',
  domain: 'acme.com',
  status: 'active',
  settings: {
    industry: 'Technology',
    jurisdiction: 'US',
    compliance_keywords: ['data privacy', 'cybersecurity', 'GDPR'],
    exclusion_terms: %w[wildlife agriculture]
  }
)

tech_startup = Organization.create!(
  name: 'TechStart Inc',
  slug: 'techstart',
  domain: 'techstart.com',
  status: 'active',
  settings: {
    industry: 'Software',
    jurisdiction: 'US',
    compliance_keywords: ['software licensing', 'intellectual property'],
    exclusion_terms: %w[manufacturing chemicals]
  }
)

# Create Departments
puts 'Creating departments...'
acme_legal = acme_corp.departments.create!(
  name: 'Legal Department',
  slug: 'legal',
  status: 'active',
  settings: {
    description: 'Handles all legal and compliance matters',
    compliance_focus: ['regulatory compliance', 'contract management'],
    department_type: 'Legal'
  }
)

acme_it = acme_corp.departments.create!(
  name: 'IT Department',
  slug: 'it',
  status: 'active',
  settings: {
    description: 'Information Technology and Security',
    compliance_focus: ['cybersecurity', 'data protection'],
    department_type: 'Technology'
  }
)

tech_legal = tech_startup.departments.create!(
  name: 'Legal & Compliance',
  slug: 'legal-compliance',
  status: 'active',
  settings: {
    description: 'Legal and compliance operations',
    compliance_focus: ['software compliance', 'licensing'],
    department_type: 'Legal'
  }
)

# Create Teams
puts 'Creating teams...'
acme_legal_compliance = acme_legal.teams.create!(
  name: 'Compliance Team',
  slug: 'compliance',
  status: 'active',
  settings: {
    description: 'Regulatory compliance specialists',
    team_type: 'Compliance',
    compliance_responsibilities: ['regulatory monitoring', 'policy development']
  }
)

acme_it_security = acme_it.teams.create!(
  name: 'Security Team',
  slug: 'security',
  status: 'active',
  settings: {
    description: 'Cybersecurity and data protection',
    team_type: 'Security',
    compliance_responsibilities: ['cybersecurity compliance', 'data protection']
  }
)

tech_compliance = tech_legal.teams.create!(
  name: 'Software Compliance',
  slug: 'software-compliance',
  status: 'active',
  settings: {
    description: 'Software licensing and IP compliance',
    team_type: 'Compliance',
    compliance_responsibilities: ['software licensing', 'IP protection']
  }
)

# Create Units
puts 'Creating units...'
acme_compliance_monitoring = acme_legal_compliance.units.create!(
  name: 'Regulatory Monitoring',
  slug: 'regulatory-monitoring',
  status: 'active',
  settings: {
    description: 'Monitors regulatory changes and updates',
    unit_type: 'Monitoring',
    compliance_focus: ['regulatory tracking', 'change management']
  }
)

acme_security_ops = acme_it_security.units.create!(
  name: 'Security Operations',
  slug: 'security-ops',
  status: 'active',
  settings: {
    description: 'Day-to-day security operations',
    unit_type: 'Operations',
    compliance_focus: ['security monitoring', 'incident response']
  }
)

tech_licensing = tech_compliance.units.create!(
  name: 'Licensing Management',
  slug: 'licensing-management',
  status: 'active',
  settings: {
    description: 'Software licensing compliance',
    unit_type: 'Management',
    compliance_focus: ['license tracking', 'compliance reporting']
  }
)

# Create Users with Roles (Rolify will create roles automatically)
puts 'Creating users...'

# Super Admin (can access everything)
super_admin = User.create!(
  email: 'admin@complianceapp.com',
  password: 'password123',
  organization: acme_corp,
  settings: {
    first_name: 'System',
    last_name: 'Administrator',
    job_title: 'Super Administrator',
    timezone: 'UTC'
  }
)
super_admin.add_role(:super_admin)

# Organization Admin for Acme
acme_admin = User.create!(
  email: 'admin@acme.com',
  password: 'password123',
  organization: acme_corp,
  settings: {
    first_name: 'John',
    last_name: 'Smith',
    job_title: 'Chief Compliance Officer',
    timezone: 'America/New_York'
  }
)
acme_admin.add_role(:organization_admin, acme_corp)

# Department Admin for Acme Legal
legal_admin = User.create!(
  email: 'legal.admin@acme.com',
  password: 'password123',
  organization: acme_corp,
  department: acme_legal,
  settings: {
    first_name: 'Sarah',
    last_name: 'Johnson',
    job_title: 'Legal Department Head',
    timezone: 'America/New_York'
  }
)
legal_admin.add_role(:department_admin, acme_legal)

# Team Lead for Compliance
compliance_lead = User.create!(
  email: 'compliance.lead@acme.com',
  password: 'password123',
  organization: acme_corp,
  department: acme_legal,
  team: acme_legal_compliance,
  settings: {
    first_name: 'Michael',
    last_name: 'Brown',
    job_title: 'Compliance Team Lead',
    timezone: 'America/New_York'
  }
)
compliance_lead.add_role(:team_lead, acme_legal_compliance)

# Unit Manager for Regulatory Monitoring
monitoring_manager = User.create!(
  email: 'monitoring.manager@acme.com',
  password: 'password123',
  organization: acme_corp,
  department: acme_legal,
  team: acme_legal_compliance,
  unit: acme_compliance_monitoring,
  settings: {
    first_name: 'Emily',
    last_name: 'Davis',
    job_title: 'Regulatory Monitoring Manager',
    timezone: 'America/New_York'
  }
)
monitoring_manager.add_role(:unit_manager, acme_compliance_monitoring)

# Compliance Officer
compliance_officer = User.create!(
  email: 'compliance.officer@acme.com',
  password: 'password123',
  organization: acme_corp,
  department: acme_legal,
  team: acme_legal_compliance,
  unit: acme_compliance_monitoring,
  settings: {
    first_name: 'David',
    last_name: 'Wilson',
    job_title: 'Compliance Officer',
    timezone: 'America/New_York'
  }
)
compliance_officer.add_role(:compliance_officer)

# Regular User
regular_user = User.create!(
  email: 'user@acme.com',
  password: 'password123',
  organization: acme_corp,
  department: acme_legal,
  team: acme_legal_compliance,
  unit: acme_compliance_monitoring,
  settings: {
    first_name: 'Lisa',
    last_name: 'Anderson',
    job_title: 'Compliance Analyst',
    timezone: 'America/New_York'
  }
)
regular_user.add_role(:user)

# TechStart Users
tech_admin = User.create!(
  email: 'admin@techstart.com',
  password: 'password123',
  organization: tech_startup,
  settings: {
    first_name: 'Alex',
    last_name: 'Chen',
    job_title: 'CTO',
    timezone: 'America/Los_Angeles'
  }
)
tech_admin.add_role(:organization_admin, tech_startup)

tech_compliance_user = User.create!(
  email: 'compliance@techstart.com',
  password: 'password123',
  organization: tech_startup,
  department: tech_legal,
  team: tech_compliance,
  unit: tech_licensing,
  settings: {
    first_name: 'Rachel',
    last_name: 'Garcia',
    job_title: 'Software Compliance Specialist',
    timezone: 'America/Los_Angeles'
  }
)
tech_compliance_user.add_role(:compliance_officer)

# Create Additional Roles for Management Interface
puts 'Creating additional roles...'

# Acme Corporation Roles
acme_roles = [
  { name: 'Compliance Manager', resource_type: 'Organization', resource: acme_corp },
  { name: 'Data Privacy Officer', resource_type: 'Organization', resource: acme_corp },
  { name: 'Security Analyst', resource_type: 'Department', resource: acme_it },
  { name: 'Legal Assistant', resource_type: 'Department', resource: acme_legal },
  { name: 'Compliance Specialist', resource_type: 'Team', resource: acme_legal_compliance },
  { name: 'Security Operator', resource_type: 'Team', resource: acme_it_security },
  { name: 'Regulatory Analyst', resource_type: 'Unit', resource: acme_compliance_monitoring },
  { name: 'Security Monitor', resource_type: 'Unit', resource: acme_security_ops }
]

acme_roles.each do |role_attrs|
  Role.find_or_create_by!(
    name: role_attrs[:name],
    resource_type: role_attrs[:resource_type],
    resource_id: role_attrs[:resource]&.id
  )
end

# TechStart Roles
tech_roles = [
  { name: 'Software Compliance Manager', resource_type: 'Organization', resource: tech_startup },
  { name: 'IP Specialist', resource_type: 'Department', resource: tech_legal },
  { name: 'License Manager', resource_type: 'Team', resource: tech_compliance },
  { name: 'Compliance Analyst', resource_type: 'Unit', resource: tech_licensing }
]

tech_roles.each do |role_attrs|
  Role.find_or_create_by!(
    name: role_attrs[:name],
    resource_type: role_attrs[:resource_type],
    resource_id: role_attrs[:resource]&.id
  )
end

# Assign some additional roles to users
puts 'Assigning additional roles to users...'

# Assign Compliance Manager role to acme_admin
compliance_manager_role = Role.find_by(name: 'Compliance Manager', resource_type: 'Organization', resource: acme_corp)
acme_admin.add_role(compliance_manager_role.name, compliance_manager_role.resource) if compliance_manager_role

# Assign Data Privacy Officer role to legal_admin
privacy_officer_role = Role.find_by(name: 'Data Privacy Officer', resource_type: 'Organization', resource: acme_corp)
legal_admin.add_role(privacy_officer_role.name, privacy_officer_role.resource) if privacy_officer_role

# Assign Security Analyst role to compliance_lead
security_analyst_role = Role.find_by(name: 'Security Analyst', resource_type: 'Department', resource: acme_it)
compliance_lead.add_role(security_analyst_role.name, security_analyst_role.resource) if security_analyst_role

# Assign Software Compliance Manager role to tech_admin
software_compliance_role = Role.find_by(name: 'Software Compliance Manager', resource_type: 'Organization',
                                        resource: tech_startup)
tech_admin.add_role(software_compliance_role.name, software_compliance_role.resource) if software_compliance_role

# Create permissions for specific organizational roles
puts 'Creating permissions for specific organizational roles...'

# Acme Corporation specific role permissions
acme_compliance_manager_role = Role.find_by(name: 'Compliance Manager', resource_type: 'Organization',
                                            resource: acme_corp)
if acme_compliance_manager_role
  create_permission(acme_corp, 'Compliance Manager - Manage Compliance', 'manage', 'Organization', acme_corp,
                    acme_compliance_manager_role)
  create_permission(acme_corp, 'Compliance Manager - Read All Users', 'read', 'User', nil, acme_compliance_manager_role)
  create_permission(acme_corp, 'Compliance Manager - Read All Departments', 'read', 'Department', nil,
                    acme_compliance_manager_role)
  create_permission(acme_corp, 'Compliance Manager - Read All Teams', 'read', 'Team', nil, acme_compliance_manager_role)
  create_permission(acme_corp, 'Compliance Manager - Read All Units', 'read', 'Unit', nil, acme_compliance_manager_role)
  create_permission(acme_corp, 'Compliance Manager - Manage Permissions', 'manage', 'Permission', nil,
                    acme_compliance_manager_role)
end

acme_privacy_officer_role = Role.find_by(name: 'Data Privacy Officer', resource_type: 'Organization',
                                         resource: acme_corp)
if acme_privacy_officer_role
  create_permission(acme_corp, 'Data Privacy Officer - Manage Privacy', 'manage', 'Organization', acme_corp,
                    acme_privacy_officer_role)
  create_permission(acme_corp, 'Data Privacy Officer - Read All Users', 'read', 'User', nil, acme_privacy_officer_role)
  create_permission(acme_corp, 'Data Privacy Officer - Read All Departments', 'read', 'Department', nil,
                    acme_privacy_officer_role)
  create_permission(acme_corp, 'Data Privacy Officer - Read All Teams', 'read', 'Team', nil, acme_privacy_officer_role)
  create_permission(acme_corp, 'Data Privacy Officer - Read All Units', 'read', 'Unit', nil, acme_privacy_officer_role)
end

acme_security_analyst_role = Role.find_by(name: 'Security Analyst', resource_type: 'Department', resource: acme_it)
if acme_security_analyst_role
  create_permission(acme_corp, 'Security Analyst - Manage IT Security', 'manage', 'Department', acme_it,
                    acme_security_analyst_role)
  create_permission(acme_corp, 'Security Analyst - Read IT Users', 'read', 'User', nil, acme_security_analyst_role, {
                      'data_conditions' => { 'department_id' => acme_it.id }
                    })
  create_permission(acme_corp, 'Security Analyst - Read IT Teams', 'read', 'Team', nil, acme_security_analyst_role, {
                      'data_conditions' => { 'department_id' => acme_it.id }
                    })
  create_permission(acme_corp, 'Security Analyst - Read IT Units', 'read', 'Unit', nil, acme_security_analyst_role, {
                      'data_conditions' => { 'department_id' => acme_it.id }
                    })
end

acme_legal_assistant_role = Role.find_by(name: 'Legal Assistant', resource_type: 'Department', resource: acme_legal)
if acme_legal_assistant_role
  create_permission(acme_corp, 'Legal Assistant - Manage Legal Department', 'manage', 'Department', acme_legal,
                    acme_legal_assistant_role)
  create_permission(acme_corp, 'Legal Assistant - Read Legal Users', 'read', 'User', nil, acme_legal_assistant_role, {
                      'data_conditions' => { 'department_id' => acme_legal.id }
                    })
  create_permission(acme_corp, 'Legal Assistant - Read Legal Teams', 'read', 'Team', nil, acme_legal_assistant_role, {
                      'data_conditions' => { 'department_id' => acme_legal.id }
                    })
  create_permission(acme_corp, 'Legal Assistant - Read Legal Units', 'read', 'Unit', nil, acme_legal_assistant_role, {
                      'data_conditions' => { 'department_id' => acme_legal.id }
                    })
end

acme_compliance_specialist_role = Role.find_by(name: 'Compliance Specialist', resource_type: 'Team',
                                               resource: acme_legal_compliance)
if acme_compliance_specialist_role
  create_permission(acme_corp, 'Compliance Specialist - Manage Compliance Team', 'manage', 'Team',
                    acme_legal_compliance, acme_compliance_specialist_role)
  create_permission(acme_corp, 'Compliance Specialist - Read Team Users', 'read', 'User', nil, acme_compliance_specialist_role, {
                      'data_conditions' => { 'team_id' => acme_legal_compliance.id }
                    })
  create_permission(acme_corp, 'Compliance Specialist - Read Team Units', 'read', 'Unit', nil, acme_compliance_specialist_role, {
                      'data_conditions' => { 'team_id' => acme_legal_compliance.id }
                    })
end

acme_security_operator_role = Role.find_by(name: 'Security Operator', resource_type: 'Team', resource: acme_it_security)
if acme_security_operator_role
  create_permission(acme_corp, 'Security Operator - Manage Security Team', 'manage', 'Team', acme_it_security,
                    acme_security_operator_role)
  create_permission(acme_corp, 'Security Operator - Read Team Users', 'read', 'User', nil, acme_security_operator_role, {
                      'data_conditions' => { 'team_id' => acme_it_security.id }
                    })
  create_permission(acme_corp, 'Security Operator - Read Team Units', 'read', 'Unit', nil, acme_security_operator_role, {
                      'data_conditions' => { 'team_id' => acme_it_security.id }
                    })
end

acme_regulatory_analyst_role = Role.find_by(name: 'Regulatory Analyst', resource_type: 'Unit',
                                            resource: acme_compliance_monitoring)
if acme_regulatory_analyst_role
  create_permission(acme_corp, 'Regulatory Analyst - Manage Monitoring Unit', 'manage', 'Unit',
                    acme_compliance_monitoring, acme_regulatory_analyst_role)
  create_permission(acme_corp, 'Regulatory Analyst - Read Unit Users', 'read', 'User', nil, acme_regulatory_analyst_role, {
                      'data_conditions' => { 'unit_id' => acme_compliance_monitoring.id }
                    })
end

acme_security_monitor_role = Role.find_by(name: 'Security Monitor', resource_type: 'Unit', resource: acme_security_ops)
if acme_security_monitor_role
  create_permission(acme_corp, 'Security Monitor - Manage Security Ops Unit', 'manage', 'Unit', acme_security_ops,
                    acme_security_monitor_role)
  create_permission(acme_corp, 'Security Monitor - Read Unit Users', 'read', 'User', nil, acme_security_monitor_role, {
                      'data_conditions' => { 'unit_id' => acme_security_ops.id }
                    })
end

# TechStart specific role permissions
tech_software_compliance_role = Role.find_by(name: 'Software Compliance Manager', resource_type: 'Organization',
                                             resource: tech_startup)
if tech_software_compliance_role
  create_permission(tech_startup, 'Software Compliance Manager - Manage Software Compliance', 'manage', 'Organization',
                    tech_startup, tech_software_compliance_role)
  create_permission(tech_startup, 'Software Compliance Manager - Read All Users', 'read', 'User', nil,
                    tech_software_compliance_role)
  create_permission(tech_startup, 'Software Compliance Manager - Read All Departments', 'read', 'Department', nil,
                    tech_software_compliance_role)
  create_permission(tech_startup, 'Software Compliance Manager - Read All Teams', 'read', 'Team', nil,
                    tech_software_compliance_role)
  create_permission(tech_startup, 'Software Compliance Manager - Read All Units', 'read', 'Unit', nil,
                    tech_software_compliance_role)
  create_permission(tech_startup, 'Software Compliance Manager - Manage Permissions', 'manage', 'Permission', nil,
                    tech_software_compliance_role)
end

tech_ip_specialist_role = Role.find_by(name: 'IP Specialist', resource_type: 'Department', resource: tech_legal)
if tech_ip_specialist_role
  create_permission(tech_startup, 'IP Specialist - Manage Legal Department', 'manage', 'Department', tech_legal,
                    tech_ip_specialist_role)
  create_permission(tech_startup, 'IP Specialist - Read Legal Users', 'read', 'User', nil, tech_ip_specialist_role, {
                      'data_conditions' => { 'department_id' => tech_legal.id }
                    })
  create_permission(tech_startup, 'IP Specialist - Read Legal Teams', 'read', 'Team', nil, tech_ip_specialist_role, {
                      'data_conditions' => { 'department_id' => tech_legal.id }
                    })
  create_permission(tech_startup, 'IP Specialist - Read Legal Units', 'read', 'Unit', nil, tech_ip_specialist_role, {
                      'data_conditions' => { 'department_id' => tech_legal.id }
                    })
end

tech_license_manager_role = Role.find_by(name: 'License Manager', resource_type: 'Team', resource: tech_compliance)
if tech_license_manager_role
  create_permission(tech_startup, 'License Manager - Manage Compliance Team', 'manage', 'Team', tech_compliance,
                    tech_license_manager_role)
  create_permission(tech_startup, 'License Manager - Read Team Users', 'read', 'User', nil, tech_license_manager_role, {
                      'data_conditions' => { 'team_id' => tech_compliance.id }
                    })
  create_permission(tech_startup, 'License Manager - Read Team Units', 'read', 'Unit', nil, tech_license_manager_role, {
                      'data_conditions' => { 'team_id' => tech_compliance.id }
                    })
end

tech_compliance_analyst_role = Role.find_by(name: 'Compliance Analyst', resource_type: 'Unit', resource: tech_licensing)
if tech_compliance_analyst_role
  create_permission(tech_startup, 'Compliance Analyst - Manage Licensing Unit', 'manage', 'Unit', tech_licensing,
                    tech_compliance_analyst_role)
  create_permission(tech_startup, 'Compliance Analyst - Read Unit Users', 'read', 'User', nil, tech_compliance_analyst_role, {
                      'data_conditions' => { 'unit_id' => tech_licensing.id }
                    })
end

# Create Permissions
puts 'Creating permissions...'

# Acme Corporation Permissions

# Super Admin gets all permissions
create_permission(acme_corp, 'Super Admin - Full Access', 'manage', 'Organization', acme_corp, super_admin)

# Organization Admin permissions
create_permission(acme_corp, 'Org Admin - Manage Organization', 'manage', 'Organization', acme_corp, acme_admin)
create_permission(acme_corp, 'Org Admin - Manage Users', 'manage', 'User', nil, acme_admin)
create_permission(acme_corp, 'Org Admin - Manage Departments', 'manage', 'Department', nil, acme_admin)
create_permission(acme_corp, 'Org Admin - Manage Teams', 'manage', 'Team', nil, acme_admin)
create_permission(acme_corp, 'Org Admin - Manage Units', 'manage', 'Unit', nil, acme_admin)
create_permission(acme_corp, 'Org Admin - Manage Permissions', 'manage', 'Permission', nil, acme_admin)

# Department Admin permissions
create_permission(acme_corp, 'Dept Admin - Manage Legal Department', 'manage', 'Department', acme_legal, legal_admin)
create_permission(acme_corp, 'Dept Admin - Manage Legal Teams', 'manage', 'Team', nil, legal_admin, {
                    'data_conditions' => { 'department_id' => acme_legal.id }
                  })
create_permission(acme_corp, 'Dept Admin - Manage Legal Units', 'manage', 'Unit', nil, legal_admin, {
                    'data_conditions' => { 'department_id' => acme_legal.id }
                  })
create_permission(acme_corp, 'Dept Admin - View Legal Users', 'read', 'User', nil, legal_admin, {
                    'data_conditions' => { 'department_id' => acme_legal.id }
                  })

# Team Lead permissions
create_permission(acme_corp, 'Team Lead - Manage Compliance Team', 'manage', 'Team', acme_legal_compliance,
                  compliance_lead)
create_permission(acme_corp, 'Team Lead - Manage Compliance Units', 'manage', 'Unit', nil, compliance_lead, {
                    'data_conditions' => { 'team_id' => acme_legal_compliance.id }
                  })
create_permission(acme_corp, 'Team Lead - View Team Users', 'read', 'User', nil, compliance_lead, {
                    'data_conditions' => { 'team_id' => acme_legal_compliance.id }
                  })

# Unit Manager permissions
create_permission(acme_corp, 'Unit Manager - Manage Monitoring Unit', 'manage', 'Unit', acme_compliance_monitoring,
                  monitoring_manager)
create_permission(acme_corp, 'Unit Manager - View Unit Users', 'read', 'User', nil, monitoring_manager, {
                    'data_conditions' => { 'unit_id' => acme_compliance_monitoring.id }
                  })

# Compliance Officer permissions
create_permission(acme_corp, 'Compliance Officer - Read All', 'read', 'Organization', acme_corp, compliance_officer)
create_permission(acme_corp, 'Compliance Officer - Read Users', 'read', 'User', nil, compliance_officer)
create_permission(acme_corp, 'Compliance Officer - Read Departments', 'read', 'Department', nil, compliance_officer)
create_permission(acme_corp, 'Compliance Officer - Read Teams', 'read', 'Team', nil, compliance_officer)
create_permission(acme_corp, 'Compliance Officer - Read Units', 'read', 'Unit', nil, compliance_officer)

# Regular User permissions
create_permission(acme_corp, 'User - Read Own Organization', 'read', 'Organization', acme_corp, regular_user)
create_permission(acme_corp, 'User - Read Own Department', 'read', 'Department', acme_legal, regular_user)
create_permission(acme_corp, 'User - Read Own Team', 'read', 'Team', acme_legal_compliance, regular_user)
create_permission(acme_corp, 'User - Read Own Unit', 'read', 'Unit', acme_compliance_monitoring, regular_user)

# Role-based permissions for Acme
acme_org_admin_role = Role.find_by(name: 'organization_admin', resource: acme_corp)
acme_dept_admin_role = Role.find_by(name: 'department_admin', resource: acme_legal)
acme_team_lead_role = Role.find_by(name: 'team_lead', resource: acme_legal_compliance)
acme_unit_manager_role = Role.find_by(name: 'unit_manager', resource: acme_compliance_monitoring)
acme_compliance_officer_role = Role.find_by(name: 'compliance_officer')
acme_user_role = Role.find_by(name: 'user')

# Role-based permissions
if acme_org_admin_role
  create_permission(acme_corp, 'Role - Org Admin - Manage Users', 'manage', 'User', nil, acme_org_admin_role)
  create_permission(acme_corp, 'Role - Org Admin - Manage Permissions', 'manage', 'Permission', nil,
                    acme_org_admin_role)
  create_permission(acme_corp, 'Role - Org Admin - Manage Roles', 'manage', 'Role', nil, acme_org_admin_role)
  create_permission(acme_corp, 'Role - Org Admin - Manage Departments', 'manage', 'Department', nil,
                    acme_org_admin_role)
  create_permission(acme_corp, 'Role - Org Admin - Manage Teams', 'manage', 'Team', nil, acme_org_admin_role)
  create_permission(acme_corp, 'Role - Org Admin - Manage Units', 'manage', 'Unit', nil, acme_org_admin_role)
  create_permission(acme_corp, 'Role - Org Admin - Read Organization', 'read', 'Organization', acme_corp,
                    acme_org_admin_role)
end

if acme_dept_admin_role
  create_permission(acme_corp, 'Role - Dept Admin - Manage Department Users', 'manage', 'User', nil, acme_dept_admin_role, {
                      'data_conditions' => { 'department_id' => acme_legal.id }
                    })
  create_permission(acme_corp, 'Role - Dept Admin - Manage Department Teams', 'manage', 'Team', nil, acme_dept_admin_role, {
                      'data_conditions' => { 'department_id' => acme_legal.id }
                    })
  create_permission(acme_corp, 'Role - Dept Admin - Manage Department Units', 'manage', 'Unit', nil, acme_dept_admin_role, {
                      'data_conditions' => { 'department_id' => acme_legal.id }
                    })
  create_permission(acme_corp, 'Role - Dept Admin - Read Department', 'read', 'Department', acme_legal,
                    acme_dept_admin_role)
end

if acme_team_lead_role
  create_permission(acme_corp, 'Role - Team Lead - Manage Team Users', 'manage', 'User', nil, acme_team_lead_role, {
                      'data_conditions' => { 'team_id' => acme_legal_compliance.id }
                    })
  create_permission(acme_corp, 'Role - Team Lead - Manage Team Units', 'manage', 'Unit', nil, acme_team_lead_role, {
                      'data_conditions' => { 'team_id' => acme_legal_compliance.id }
                    })
  create_permission(acme_corp, 'Role - Team Lead - Read Team', 'read', 'Team', acme_legal_compliance,
                    acme_team_lead_role)
end

if acme_unit_manager_role
  create_permission(acme_corp, 'Role - Unit Manager - Manage Unit Users', 'manage', 'User', nil, acme_unit_manager_role, {
                      'data_conditions' => { 'unit_id' => acme_compliance_monitoring.id }
                    })
  create_permission(acme_corp, 'Role - Unit Manager - Read Unit', 'read', 'Unit', acme_compliance_monitoring,
                    acme_unit_manager_role)
end

if acme_compliance_officer_role
  create_permission(acme_corp, 'Role - Compliance Officer - Read All', 'read', 'Organization', acme_corp,
                    acme_compliance_officer_role)
  create_permission(acme_corp, 'Role - Compliance Officer - Read Users', 'read', 'User', nil,
                    acme_compliance_officer_role)
  create_permission(acme_corp, 'Role - Compliance Officer - Read Departments', 'read', 'Department', nil,
                    acme_compliance_officer_role)
  create_permission(acme_corp, 'Role - Compliance Officer - Read Teams', 'read', 'Team', nil,
                    acme_compliance_officer_role)
  create_permission(acme_corp, 'Role - Compliance Officer - Read Units', 'read', 'Unit', nil,
                    acme_compliance_officer_role)
end

if acme_user_role
  create_permission(acme_corp, 'Role - User - Read Own Organization', 'read', 'Organization', acme_corp, acme_user_role)
  create_permission(acme_corp, 'Role - User - Read Own Department', 'read', 'Department', acme_legal, acme_user_role)
  create_permission(acme_corp, 'Role - User - Read Own Team', 'read', 'Team', acme_legal_compliance, acme_user_role)
  create_permission(acme_corp, 'Role - User - Read Own Unit', 'read', 'Unit', acme_compliance_monitoring,
                    acme_user_role)
end

# TechStart Permissions
create_permission(tech_startup, 'TechStart Admin - Full Access', 'manage', 'Organization', tech_startup, tech_admin)
create_permission(tech_startup, 'TechStart Admin - Manage Users', 'manage', 'User', nil, tech_admin)
create_permission(tech_startup, 'TechStart Admin - Manage Departments', 'manage', 'Department', nil, tech_admin)
create_permission(tech_startup, 'TechStart Admin - Manage Teams', 'manage', 'Team', nil, tech_admin)
create_permission(tech_startup, 'TechStart Admin - Manage Units', 'manage', 'Unit', nil, tech_admin)
create_permission(tech_startup, 'TechStart Admin - Manage Permissions', 'manage', 'Permission', nil, tech_admin)
create_permission(tech_startup, 'TechStart Admin - Manage Roles', 'manage', 'Role', nil, tech_admin)

create_permission(tech_startup, 'TechStart Compliance - Read Access', 'read', 'Organization', tech_startup,
                  tech_compliance_user)
create_permission(tech_startup, 'TechStart Compliance - Read Users', 'read', 'User', nil, tech_compliance_user)
create_permission(tech_startup, 'TechStart Compliance - Read Departments', 'read', 'Department', nil,
                  tech_compliance_user)
create_permission(tech_startup, 'TechStart Compliance - Read Teams', 'read', 'Team', nil, tech_compliance_user)
create_permission(tech_startup, 'TechStart Compliance - Read Units', 'read', 'Unit', nil, tech_compliance_user)

# TechStart Role-based permissions
tech_org_admin_role = Role.find_by(name: 'organization_admin', resource: tech_startup)
tech_dept_admin_role = Role.find_by(name: 'department_admin', resource: tech_legal)
tech_team_lead_role = Role.find_by(name: 'team_lead', resource: tech_compliance)
tech_unit_manager_role = Role.find_by(name: 'unit_manager', resource: tech_licensing)
tech_compliance_officer_role = Role.find_by(name: 'compliance_officer')
tech_user_role = Role.find_by(name: 'user')

if tech_org_admin_role
  create_permission(tech_startup, 'TechStart Role - Org Admin - Manage Users', 'manage', 'User', nil,
                    tech_org_admin_role)
  create_permission(tech_startup, 'TechStart Role - Org Admin - Manage Permissions', 'manage', 'Permission', nil,
                    tech_org_admin_role)
  create_permission(tech_startup, 'TechStart Role - Org Admin - Manage Roles', 'manage', 'Role', nil,
                    tech_org_admin_role)
  create_permission(tech_startup, 'TechStart Role - Org Admin - Manage Departments', 'manage', 'Department', nil,
                    tech_org_admin_role)
  create_permission(tech_startup, 'TechStart Role - Org Admin - Manage Teams', 'manage', 'Team', nil,
                    tech_org_admin_role)
  create_permission(tech_startup, 'TechStart Role - Org Admin - Manage Units', 'manage', 'Unit', nil,
                    tech_org_admin_role)
  create_permission(tech_startup, 'TechStart Role - Org Admin - Read Organization', 'read', 'Organization',
                    tech_startup, tech_org_admin_role)
end

if tech_dept_admin_role
  create_permission(tech_startup, 'TechStart Role - Dept Admin - Manage Department Users', 'manage', 'User', nil, tech_dept_admin_role, {
                      'data_conditions' => { 'department_id' => tech_legal.id }
                    })
  create_permission(tech_startup, 'TechStart Role - Dept Admin - Manage Department Teams', 'manage', 'Team', nil, tech_dept_admin_role, {
                      'data_conditions' => { 'department_id' => tech_legal.id }
                    })
  create_permission(tech_startup, 'TechStart Role - Dept Admin - Manage Department Units', 'manage', 'Unit', nil, tech_dept_admin_role, {
                      'data_conditions' => { 'department_id' => tech_legal.id }
                    })
  create_permission(tech_startup, 'TechStart Role - Dept Admin - Read Department', 'read', 'Department', tech_legal,
                    tech_dept_admin_role)
end

if tech_team_lead_role
  create_permission(tech_startup, 'TechStart Role - Team Lead - Manage Team Users', 'manage', 'User', nil, tech_team_lead_role, {
                      'data_conditions' => { 'team_id' => tech_compliance.id }
                    })
  create_permission(tech_startup, 'TechStart Role - Team Lead - Manage Team Units', 'manage', 'Unit', nil, tech_team_lead_role, {
                      'data_conditions' => { 'team_id' => tech_compliance.id }
                    })
  create_permission(tech_startup, 'TechStart Role - Team Lead - Read Team', 'read', 'Team', tech_compliance,
                    tech_team_lead_role)
end

if tech_unit_manager_role
  create_permission(tech_startup, 'TechStart Role - Unit Manager - Manage Unit Users', 'manage', 'User', nil, tech_unit_manager_role, {
                      'data_conditions' => { 'unit_id' => tech_licensing.id }
                    })
  create_permission(tech_startup, 'TechStart Role - Unit Manager - Read Unit', 'read', 'Unit', tech_licensing,
                    tech_unit_manager_role)
end

if tech_compliance_officer_role
  create_permission(tech_startup, 'TechStart Role - Compliance Officer - Read All', 'read', 'Organization',
                    tech_startup, tech_compliance_officer_role)
  create_permission(tech_startup, 'TechStart Role - Compliance Officer - Read Users', 'read', 'User', nil,
                    tech_compliance_officer_role)
  create_permission(tech_startup, 'TechStart Role - Compliance Officer - Read Departments', 'read', 'Department', nil,
                    tech_compliance_officer_role)
  create_permission(tech_startup, 'TechStart Role - Compliance Officer - Read Teams', 'read', 'Team', nil,
                    tech_compliance_officer_role)
  create_permission(tech_startup, 'TechStart Role - Compliance Officer - Read Units', 'read', 'Unit', nil,
                    tech_compliance_officer_role)
end

if tech_user_role
  create_permission(tech_startup, 'TechStart Role - User - Read Own Organization', 'read', 'Organization',
                    tech_startup, tech_user_role)
  create_permission(tech_startup, 'TechStart Role - User - Read Own Department', 'read', 'Department', tech_legal,
                    tech_user_role)
  create_permission(tech_startup, 'TechStart Role - User - Read Own Team', 'read', 'Team', tech_compliance,
                    tech_user_role)
  create_permission(tech_startup, 'TechStart Role - User - Read Own Unit', 'read', 'Unit', tech_licensing,
                    tech_user_role)
end

# Time-based permissions example
create_permission(acme_corp, 'Business Hours Only - User Management', 'manage', 'User', nil, acme_admin, {
                    'time_conditions' => {
                      'start_time' => '09:00',
                      'end_time' => '17:00',
                      'days' => %w[monday tuesday wednesday thursday friday]
                    }
                  })

# User condition permissions example
create_permission(acme_corp, 'Department Specific - Legal Only', 'read', 'Department', acme_legal, regular_user, {
                    'user_conditions' => { 'department_id' => acme_legal.id }
                  })

puts 'Seed data created successfully!'
puts "Organizations: #{Organization.count}"
puts "Departments: #{Department.count}"
puts "Teams: #{Team.count}"
puts "Units: #{Unit.count}"
puts "Users: #{User.count}"
puts "Roles: #{Role.count}"
puts "Permissions: #{Permission.count}"

puts "\nTest Accounts:"
puts 'Super Admin: admin@complianceapp.com / password123'
puts 'Acme Admin: admin@acme.com / password123'
puts 'TechStart Admin: admin@techstart.com / password123'
puts 'Regular User: user@acme.com / password123'

puts "\nPermission Examples Created:"
puts '- Super Admin: Full access to everything'
puts '- Organization Admin: Manage organization, users, departments, teams, units, permissions'
puts '- Department Admin: Manage their department and related teams/units'
puts '- Team Lead: Manage their team and related units'
puts '- Unit Manager: Manage their unit'
puts '- Compliance Officer: Read access to all organizational data'
puts '- Regular User: Read access to their own organizational hierarchy'
puts '- Role-based permissions for dynamic assignment'
puts '- Time-based permissions (business hours only)'
puts '- User condition permissions (department-specific)'
