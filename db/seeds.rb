# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clear existing data
puts 'Clearing existing data...'
User.destroy_all
Organization.destroy_all
Role.destroy_all
Permission.destroy_all
Provider.destroy_all
ComplianceFramework.destroy_all
ComplianceRequirement.destroy_all
ComplianceControl.destroy_all
Document.destroy_all
Regulation.destroy_all
OrganizationRegulation.destroy_all

# Create organizations
puts 'Creating organizations...'
orgs = []

orgs << Organization.create!(
  name: 'Acme Corporation',
  slug: 'acme-corporation',
  domain: 'acme-corp.com',
  status: 'active',
  settings: {
    industry: 'Technology',
    jurisdiction: 'US',
    size: 'large',
    description: 'A leading technology company specializing in software solutions',
    website: 'https://acme-corp.com',
    contact_email: 'info@acme-corp.com',
    contact_phone: '+1-555-0123',
    state: 'California',
    country: 'United States',
    timezone: 'America/Los_Angeles',
    locale: 'en',
    currency: 'USD',
    primary_color: '#2563EB',
    secondary_color: '#64748B',
    accent_color: '#10B981',
    brand_colors: {
      primary: '#2563EB',
      secondary: '#64748B',
      accent: '#10B981',
      text: '#1F2937',
      background: '#FFFFFF',
      success: '#10B981',
      warning: '#F59E0B',
      error: '#EF4444'
    },
    privacy_level: 'standard',
    data_retention_days: 2555,
    allow_external_sharing: true,
    require_2fa: true,
    session_timeout_minutes: 480,
    auto_approval_enabled: false,
    document_expiry_warning_days: 30,
    compliance_keywords: ['SOX', 'GDPR', 'ISO 27001'],
    exclusion_terms: %w[confidential internal],
    notification_preferences: {
      email: { document_approval: true, compliance_deadlines: true, risk_alerts: true },
      in_app: { document_approval: true, compliance_deadlines: true, risk_alerts: true },
      frequency: 'immediate'
    },
    ai_settings: { content_analysis: true, risk_assessment: true, auto_tagging: true },
    show_analytics: true,
    show_recommendations: true,
    api_enabled: true
  }
)

orgs << Organization.create!(
  name: 'Global Financial Services',
  slug: 'global-financial-services',
  domain: 'globalfinancial.com',
  status: 'active',
  settings: {
    industry: 'Financial Services',
    jurisdiction: 'US',
    size: 'large',
    description: 'International financial services and banking',
    website: 'https://globalfinancial.com',
    contact_email: 'contact@globalfinancial.com',
    contact_phone: '+1-555-0456',
    state: 'New York',
    country: 'United States',
    timezone: 'America/New_York',
    locale: 'en',
    currency: 'USD',
    primary_color: '#059669',
    secondary_color: '#374151',
    accent_color: '#F59E0B',
    brand_colors: {
      primary: '#059669',
      secondary: '#374151',
      accent: '#F59E0B',
      text: '#111827',
      background: '#F9FAFB',
      success: '#059669',
      warning: '#F59E0B',
      error: '#DC2626'
    },
    privacy_level: 'high',
    data_retention_days: 3650,
    allow_external_sharing: false,
    require_2fa: true,
    session_timeout_minutes: 240,
    auto_approval_enabled: false,
    document_expiry_warning_days: 60,
    compliance_keywords: ['SOX', 'GLBA', 'PCI DSS', 'Basel III'],
    exclusion_terms: %w[confidential restricted internal],
    notification_preferences: {
      email: { document_approval: true, compliance_deadlines: true, risk_alerts: true },
      in_app: { document_approval: true, compliance_deadlines: true, risk_alerts: true },
      frequency: 'immediate'
    },
    ai_settings: { content_analysis: true, risk_assessment: true, compliance_mapping: true },
    show_analytics: true,
    show_recommendations: false,
    api_enabled: false
  }
)

orgs << Organization.create!(
  name: 'Healthcare Solutions Inc',
  slug: 'healthcare-solutions-inc',
  domain: 'healthcare-solutions.com',
  status: 'active',
  settings: {
    industry: 'Healthcare',
    jurisdiction: 'US',
    size: 'medium',
    description: 'Healthcare technology and compliance solutions',
    website: 'https://healthcare-solutions.com',
    contact_email: 'info@healthcare-solutions.com',
    contact_phone: '+1-555-0789',
    state: 'Texas',
    country: 'United States',
    timezone: 'America/Chicago',
    locale: 'en',
    currency: 'USD',
    primary_color: '#7C3AED',
    secondary_color: '#6B7280',
    accent_color: '#EC4899',
    brand_colors: {
      primary: '#7C3AED',
      secondary: '#6B7280',
      accent: '#EC4899',
      text: '#1F2937',
      background: '#FFFFFF',
      success: '#10B981',
      warning: '#F59E0B',
      error: '#EF4444'
    },
    privacy_level: 'high',
    data_retention_days: 2555,
    allow_external_sharing: false,
    require_2fa: true,
    session_timeout_minutes: 360,
    auto_approval_enabled: false,
    document_expiry_warning_days: 45,
    compliance_keywords: ['HIPAA', 'HITECH', 'FDA', 'ISO 13485'],
    exclusion_terms: %w[PHI confidential restricted],
    notification_preferences: {
      email: { document_approval: true, compliance_deadlines: true, risk_alerts: true },
      in_app: { document_approval: true, compliance_deadlines: true, risk_alerts: true },
      frequency: 'daily'
    },
    ai_settings: { content_analysis: true, risk_assessment: true, document_summarization: true },
    show_analytics: true,
    show_recommendations: true,
    api_enabled: true
  }
)

# Create admin users for each organization
puts 'Creating users...'
users = []

orgs.each_with_index do |org, index|
  if index == 0
    # Create super admin user assigned to first organization but with global permissions
    admin_user = User.create!(
      email: "admin#{index + 1}@example.com",
      password: 'password123',
      password_confirmation: 'password123',
      organization: org, # Assign to first organization to satisfy DB constraint
      settings: {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        job_title: 'Super Administrator',
        phone: Faker::PhoneNumber.phone_number,
        timezone: org.settings['timezone'],
        notification_settings: {
          email: true,
          in_app: true,
          frequency: 'daily'
        }
      }
    )
    puts "✓ Created Super Admin user: #{admin_user.email} (assigned to #{org.name} but will have global permissions)"
  else
    # Create regular admin users with organization
    admin_user = User.create!(
      email: "admin#{index + 1}@example.com",
      password: 'password123',
      password_confirmation: 'password123',
      organization: org,
      settings: {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        job_title: 'Administrator',
        phone: Faker::PhoneNumber.phone_number,
        timezone: org.settings['timezone'],
        notification_settings: {
          email: true,
          in_app: true,
          frequency: 'daily'
        }
      }
    )
  end
  users << admin_user

  # Create regular users
  3.times do |user_index|
    user = User.create!(
      email: "user#{index + 1}_#{user_index + 1}@example.com",
      password: 'password123',
      password_confirmation: 'password123',
      organization: org,
      settings: {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        job_title: Faker::Job.title,
        phone: Faker::PhoneNumber.phone_number,
        timezone: org.settings['timezone'],
        notification_settings: {
          email: true,
          in_app: true,
          frequency: 'daily'
        }
      }
    )
    users << user
  end
end

# Create roles
puts 'Creating roles...'
roles = []

# Global roles (not tied to any organization)
roles << Role.create!(
  name: 'Super Admin',
  organization: nil
)

roles << Role.create!(
  name: 'Platform Admin',
  organization: nil
)

# Organization-specific roles
orgs.each do |org|
  roles << Role.create!(
    name: 'Admin',
    organization: org
  )

  roles << Role.create!(
    name: 'Compliance Manager',
    organization: org
  )

  roles << Role.create!(
    name: 'Document Manager',
    organization: org
  )

  roles << Role.create!(
    name: 'User',
    organization: org
  )
end

# Assign roles to users
puts 'Assigning roles to users...'

# Assign super admin role to first admin user
if users.first
  puts "  Assigning Super Admin role to #{users.first.email} (organization: #{users.first.organization&.name || 'None'})"
  users.first.add_role('Super Admin')
  puts "  ✓ Assigned Super Admin role to #{users.first.email}"
  puts "  User roles after assignment: #{users.first.roles.pluck(:name).join(', ')}"
end

# Assign organization-specific roles
orgs.each_with_index do |org, org_index|
  admin_user = users.find { |u| u.organization == org }
  next unless admin_user

  # Assign Admin role to admin user
  puts "  Assigning Admin role to #{admin_user.email} in #{org.name}"
  admin_user.add_role('Admin', org)
  puts "  ✓ Assigned Admin role to #{admin_user.email} in #{org.name}"
  puts "  User roles after assignment: #{admin_user.roles.pluck(:name).join(', ')}"

  # Assign other roles to regular users
  org_users = users.select { |u| u.organization == org && u != admin_user }
  role_names = ['Compliance Manager', 'Document Manager', 'User']

  org_users.each_with_index do |user, user_index|
    role_name = role_names[user_index % role_names.count]
    puts "  Assigning #{role_name} role to #{user.email} in #{org.name}"
    user.add_role(role_name, org)
    puts "  ✓ Assigned #{role_name} role to #{user.email} in #{org.name}"
  end
end

# Create permissions
puts 'Creating permissions...'
permissions = []

# Get all models that inherit from ApplicationRecord (excluding abstract classes)
# Use a more reliable method to get models
resource_types = []
ObjectSpace.each_object(Class) do |klass|
  resource_types << klass.name if klass < ApplicationRecord && !klass.abstract_class? && klass.name.present?
end

# Fallback to manual list if automatic detection fails
if resource_types.empty?
  puts '  Warning: Could not automatically detect models, using manual list'
  resource_types = %w[User Organization Role Permission Provider ComplianceFramework ComplianceRequirement
                      ComplianceControl Document Regulation OrganizationRegulation Department Team Unit RiskAssessment]
end

puts "  Found #{resource_types.count} resource types: #{resource_types.join(', ')}"

# Create global permissions for Super Admin role
puts 'Creating global permissions for Super Admin...'
super_admin_role = Role.find_by(name: 'Super Admin', organization: nil)
if super_admin_role
  resource_types.each do |current_resource_type|
    puts "    Creating global permissions for resource_type: '#{current_resource_type}'"

    # Skip if resource_type is blank
    if current_resource_type.blank?
      puts '    Skipping blank resource_type'
      next
    end

    %w[create read update destroy manage assign delegate].each do |action|
      puts "      Creating global permission: #{action}_#{current_resource_type.underscore}"

      # Use raw SQL to create global permissions (no organization_id)
      sql = <<-SQL
        INSERT INTO permissions (name, resource_type, resource_id, action, grantee_type, grantee_id, organization_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      SQL

      permission_name = "global_#{action}_#{current_resource_type.underscore}"

      puts '        Global permission attributes before save:'
      puts "          name: '#{permission_name}'"
      puts "          resource_type: '#{current_resource_type}'"
      puts "          action: '#{action}'"
      puts "          grantee: #{super_admin_role.class.name} (id: #{super_admin_role.id})"
      puts '          organization_id: NULL (global)'

      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql([
                                          sql,
                                          permission_name,
                                          current_resource_type,
                                          nil, # resource_id
                                          action,
                                          'Role',
                                          super_admin_role.id,
                                          nil # organization_id for global permissions
                                        ])
      )

      # Get the created permission for the array
      permission = Permission.find_by(name: permission_name, organization_id: nil)
      permissions << permission if permission
    end
  end
end

# Create organization-specific permissions
orgs.each do |org|
  # Get the admin role for this organization
  admin_role = Role.find_by(name: 'Admin', organization: org)
  next unless admin_role

  # Create permissions for each resource type
  resource_types.each do |current_resource_type|
    puts "    Creating permissions for resource_type: '#{current_resource_type}' (class: #{current_resource_type.class})"

    # Skip if resource_type is blank
    if current_resource_type.blank?
      puts '    Skipping blank resource_type'
      next
    end

    %w[create read update destroy manage assign delegate].each do |action|
      puts "      Creating permission: #{action}_#{current_resource_type.underscore} with resource_type: '#{current_resource_type}'"

      # Use raw SQL to bypass any potential interference from acts_as_tenant
      sql = <<-SQL
        INSERT INTO permissions (name, resource_type, resource_id, action, grantee_type, grantee_id, organization_id, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, NOW(), NOW())
      SQL

      permission_name = "#{action}_#{current_resource_type.underscore}"

      puts '        Permission attributes before save:'
      puts "          name: '#{permission_name}'"
      puts "          resource_type: '#{current_resource_type}'"
      puts "          action: '#{action}'"
      puts "          grantee: #{admin_role.class.name} (id: #{admin_role.id})"
      puts "          organization: #{org.name} (id: #{org.id})"

      ActiveRecord::Base.connection.execute(
        ActiveRecord::Base.sanitize_sql([
                                          sql,
                                          permission_name,
                                          current_resource_type,
                                          nil, # resource_id
                                          action,
                                          'Role',
                                          admin_role.id,
                                          org.id
                                        ])
      )

      # Get the created permission for the array
      permission = Permission.find_by(name: permission_name, organization: org)
      permissions << permission if permission
    end
  end
end

# Create providers
puts 'Creating providers...'
providers = []

# Platform-wide providers
providers << Provider.create!(
  name: 'Securities and Exchange Commission',
  code: 'SEC',
  description: 'Federal securities regulator',
  jurisdiction: 'US',
  country: 'United States',
  provider_type: 'platform_wide',
  website: 'https://www.sec.gov',
  contact_info: {
    email: 'info@sec.gov',
    primary_contact: 'SEC Information Office'
  },
  organization: nil
)

providers << Provider.create!(
  name: 'Financial Industry Regulatory Authority',
  code: 'FINRA',
  description: 'Self-regulatory organization for broker-dealers',
  jurisdiction: 'US',
  country: 'United States',
  provider_type: 'platform_wide',
  website: 'https://www.finra.org',
  contact_info: {
    email: 'info@finra.org',
    primary_contact: 'FINRA Information Office'
  },
  organization: nil
)

providers << Provider.create!(
  name: 'European Banking Authority',
  code: 'EBA',
  description: 'EU banking regulator',
  jurisdiction: 'EU',
  country: 'European Union',
  provider_type: 'platform_wide',
  website: 'https://www.eba.europa.eu',
  contact_info: {
    email: 'info@eba.europa.eu',
    primary_contact: 'EBA Information Office'
  },
  organization: nil
)

# Organization-specific providers
orgs.each do |org|
  # Generate a shorter code that fits within 20 characters
  org_code = org.name.upcase.gsub(/\s+/, '').first(12) # Take first 12 chars of org name
  provider_code = "#{org_code}_COMP" # Total: max 17 chars (12 + 5)

  providers << Provider.create!(
    name: "#{org.name} Internal Compliance",
    code: provider_code,
    description: "Internal compliance team for #{org.name}",
    jurisdiction: org.settings['jurisdiction'] || 'US',
    country: org.settings['country'] || 'United States',
    provider_type: 'organization_specific',
    website: org.settings['website'],
    contact_info: {
      email: org.settings['contact_email'],
      primary_contact: "#{org.name} Compliance Team"
    },
    organization: org
  )
end

# Create compliance frameworks
puts 'Creating compliance frameworks...'
frameworks = []

# SEC Frameworks
sec_provider = Provider.find_by(code: 'SEC')
if sec_provider
  frameworks << ComplianceFramework.create!(
    name: 'SEC Regulation S-P: Privacy of Consumer Financial Information',
    slug: 'sec-regulation-s-p',
    description: 'Regulation S-P requires broker-dealers, investment companies, and investment advisers to adopt written policies and procedures that address administrative, technical, and physical safeguards for the protection of customer records and information.',
    version: '1.0',
    jurisdiction: 'US',
    provider: sec_provider,
    issuance_type: 'Final_Rule',
    publication_date: Date.new(2000, 6, 22),
    provider_url: 'https://www.sec.gov/rules/final/34-42974.htm',
    enforcement_date: Date.new(2001, 7, 1),
    potentially_impacted_departments: 'IT, Legal, Compliance, Operations',
    status: 'active',
    organization: orgs.first,
    settings: {
      framework_type: 'privacy',
      effective_date: Date.new(2000, 11, 13),
      industry_scope: %w[financial_services investment_management],
      review_frequency: 'annually'
    }
  )

  frameworks << ComplianceFramework.create!(
    name: 'SEC Regulation S-ID: Identity Theft Red Flags',
    slug: 'sec-regulation-s-id',
    description: 'Regulation S-ID requires certain financial institutions and creditors to develop and implement a written Identity Theft Prevention Program designed to detect, prevent, and mitigate identity theft in connection with certain existing accounts or the opening of certain new accounts.',
    version: '1.0',
    jurisdiction: 'US',
    provider: sec_provider,
    issuance_type: 'Final_Rule',
    publication_date: Date.new(2013, 4, 10),
    provider_url: 'https://www.sec.gov/rules/final/2013/34-69359.pdf',
    enforcement_date: Date.new(2013, 11, 20),
    potentially_impacted_departments: 'IT, Security, Compliance, Customer Service',
    status: 'active',
    organization: orgs.second,
    settings: {
      framework_type: 'security',
      effective_date: Date.new(2013, 5, 20),
      industry_scope: %w[financial_services banking],
      review_frequency: 'quarterly'
    }
  )
end

# FINRA Frameworks
finra_provider = Provider.find_by(code: 'FINRA')
if finra_provider
  frameworks << ComplianceFramework.create!(
    name: 'FINRA Rule 3110: Supervision',
    slug: 'finra-rule-3110',
    description: 'FINRA Rule 3110 requires member firms to establish and maintain a system to supervise the activities of each associated person that is reasonably designed to achieve compliance with applicable securities laws and regulations.',
    version: '1.0',
    jurisdiction: 'US',
    provider: finra_provider,
    issuance_type: 'Guidance',
    publication_date: Date.new(2014, 12, 1),
    provider_url: 'https://www.finra.org/rules-guidance/rulebooks/finra-rules/3110',
    enforcement_date: Date.new(2015, 3, 1),
    potentially_impacted_departments: 'Compliance, Supervision, Operations, Legal',
    status: 'active',
    organization: orgs.third,
    settings: {
      framework_type: 'supervision',
      effective_date: Date.new(2015, 3, 1),
      industry_scope: %w[broker_dealers securities],
      review_frequency: 'monthly'
    }
  )
end

# GDPR Framework
eba_provider = Provider.find_by(code: 'EBA')
if eba_provider
  frameworks << ComplianceFramework.create!(
    name: 'General Data Protection Regulation (GDPR)',
    slug: 'gdpr',
    description: 'The GDPR is a regulation in EU law on data protection and privacy in the European Union and the European Economic Area. It also addresses the transfer of personal data outside the EU and EEA areas.',
    version: '1.0',
    jurisdiction: 'EU',
    provider: eba_provider,
    issuance_type: 'Guidance',
    publication_date: Date.new(2016, 4, 27),
    provider_url: 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32016R0679',
    enforcement_date: Date.new(2018, 5, 25),
    potentially_impacted_departments: 'IT, Legal, Compliance, HR, Marketing',
    status: 'active',
    organization: orgs.first,
    settings: {
      framework_type: 'privacy',
      effective_date: Date.new(2018, 5, 25),
      industry_scope: ['all'],
      review_frequency: 'quarterly'
    }
  )
end

# Create compliance requirements
puts 'Creating compliance requirements...'
requirements = []

frameworks.each do |framework|
  3.times do |i|
    requirements << ComplianceRequirement.create!(
      name: "#{framework.name} - Requirement #{i + 1}",
      code: "REQ-#{framework.id}-#{i + 1}",
      description: Faker::Lorem.paragraph(sentence_count: 3),
      compliance_framework: framework,
      requirement_type: %w[legal_basis data_subject_rights risk_assessment].sample,
      priority: %w[high medium low].sample,
      status: %w[active inactive draft].sample,
      organization: framework.organization,
      settings: {
        category: %w[technical operational administrative].sample,
        due_date: Faker::Date.forward(days: 365),
        responsible_party: Faker::Name.name
      }
    )
  end
end

# Create compliance controls
puts 'Creating compliance controls...'
controls = []

requirements.each do |requirement|
  2.times do |i|
    controls << ComplianceControl.create!(
      name: "#{requirement.name} - Control #{i + 1}",
      description: Faker::Lorem.paragraph(sentence_count: 2),
      compliance_requirement: requirement,
      control_type: %w[preventive detective corrective].sample,
      effectiveness: %w[low medium high].sample,
      status: %w[active inactive draft].sample,
      organization: requirement.organization,
      settings: {
        control_category: %w[technical operational administrative].sample,
        frequency: %w[daily weekly monthly quarterly annually].sample,
        responsible_party: Faker::Name.name,
        implementation_date: Faker::Date.backward(days: 30)
      }
    )
  end
end

# Generate sample documents
puts 'Generating sample documents...'
orgs.each do |org|
  puts "  Generating documents for organization: #{org.name}"
  generator = DocumentGeneratorService.new(org)

  # Generate different types of documents for each organization
  %w[text word excel powerpoint pdf].each_with_index do |type, index|
    puts "    Generating #{type} document..."
    document = generator.generate_document(type, index + 1)
    if document
      puts "    ✓ Created #{type} document for #{org.name}: #{document.title}"
    else
      puts "    ✗ Failed to create #{type} document for #{org.name}"
    end
  end
end

# Create sample regulations for testing auto-assignment
puts "\nCreating sample regulations..."
regulations = []

# Financial Services Regulations
regulations << Regulation.create!(
  title: 'Sarbanes-Oxley Act (SOX) Section 404',
  agency: 'SEC',
  jurisdiction: 'US',
  reg_type: 'federal_law',
  version: 1,
  effective_date: Date.new(2002, 7, 30),
  status: 'active',
  external_id: 'SOX-404',
  full_text: {
    'main' => 'Section 404 of the Sarbanes-Oxley Act requires management and the external auditor to report on the adequacy of the company\'s internal control on financial reporting.',
    'sections' => {
      '404a' => 'Management Assessment of Internal Controls',
      '404b' => 'Auditor Attestation of Internal Controls'
    }
  },
  files: {
    'pdf' => 'https://www.sec.gov/about/laws/soa2002.pdf',
    'summary' => 'https://www.sec.gov/spotlight/sarbanes-oxley.htm'
  },
  metadata: {
    'industries' => %w[financial_services technology healthcare],
    'sectors' => %w[public_companies accounting],
    'data_types' => %w[financial_data personal_data],
    'geographic_scope' => %w[domestic international],
    'risk_level' => 'high',
    'keywords' => %w[SOX internal_controls financial_reporting audit],
    'source_url' => 'https://www.sec.gov/about/laws/soa2002.pdf',
    'tags' => %w[financial compliance audit internal_controls]
  }
)

regulations << Regulation.create!(
  title: 'Gramm-Leach-Bliley Act (GLBA) Privacy Rule',
  agency: 'FTC',
  jurisdiction: 'US',
  reg_type: 'federal_law',
  version: 1,
  effective_date: Date.new(2000, 5, 12),
  status: 'active',
  external_id: 'GLBA-PRIVACY',
  full_text: {
    'main' => 'The GLBA Privacy Rule requires financial institutions to provide customers with a clear, conspicuous, and accurate statement of their information-sharing practices.',
    'sections' => {
      'privacy_notice' => 'Requirements for Privacy Notices',
      'opt_out' => 'Customer Opt-Out Rights',
      'safeguards' => 'Information Security Safeguards'
    }
  },
  files: {
    'pdf' => 'https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/privacy-consumer-financial-information',
    'summary' => 'https://www.ftc.gov/tips-advice/business-center/privacy-and-security/gramm-leach-bliley-act'
  },
  metadata: {
    'industries' => %w[financial_services banking insurance],
    'sectors' => %w[consumer_finance privacy],
    'data_types' => %w[personal_data financial_data],
    'geographic_scope' => ['domestic'],
    'risk_level' => 'high',
    'keywords' => %w[GLBA privacy financial_institutions consumer_data],
    'source_url' => 'https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/privacy-consumer-financial-information',
    'tags' => %w[privacy financial consumer_protection]
  }
)

# Healthcare Regulations
regulations << Regulation.create!(
  title: 'Health Insurance Portability and Accountability Act (HIPAA) Privacy Rule',
  agency: 'HHS',
  jurisdiction: 'US',
  reg_type: 'federal_law',
  version: 1,
  effective_date: Date.new(2003, 4, 14),
  status: 'active',
  external_id: 'HIPAA-PRIVACY',
  full_text: {
    'main' => 'The HIPAA Privacy Rule establishes national standards to protect individuals\' medical records and other personal health information.',
    'sections' => {
      'covered_entities' => 'Definition of Covered Entities',
      'protected_health_information' => 'Definition of PHI',
      'permitted_uses' => 'Permitted Uses and Disclosures'
    }
  },
  files: {
    'pdf' => 'https://www.hhs.gov/hipaa/for-professionals/privacy/index.html',
    'summary' => 'https://www.hhs.gov/hipaa/for-individuals/index.html'
  },
  metadata: {
    'industries' => %w[healthcare insurance],
    'sectors' => %w[healthcare_providers health_plans healthcare_clearinghouses],
    'data_types' => %w[health_data personal_data],
    'geographic_scope' => ['domestic'],
    'risk_level' => 'high',
    'keywords' => %w[HIPAA privacy health_data PHI],
    'source_url' => 'https://www.hhs.gov/hipaa/for-professionals/privacy/index.html',
    'tags' => %w[healthcare privacy PHI compliance]
  }
)

# Technology Regulations
regulations << Regulation.create!(
  title: 'California Consumer Privacy Act (CCPA)',
  agency: 'California Attorney General',
  jurisdiction: 'CA',
  reg_type: 'state_law',
  version: 1,
  effective_date: Date.new(2020, 1, 1),
  status: 'active',
  external_id: 'CCPA-2020',
  full_text: {
    'main' => 'The CCPA gives California residents the right to know what personal information is being collected about them and whether it is sold or disclosed.',
    'sections' => {
      'consumer_rights' => 'Consumer Rights Under CCPA',
      'business_obligations' => 'Business Obligations',
      'enforcement' => 'Enforcement and Penalties'
    }
  },
  files: {
    'pdf' => 'https://oag.ca.gov/privacy/ccpa',
    'summary' => 'https://oag.ca.gov/privacy/ccpa-resources'
  },
  metadata: {
    'industries' => %w[technology retail financial_services],
    'sectors' => %w[consumer_privacy data_protection],
    'data_types' => %w[personal_data consumer_data],
    'geographic_scope' => ['domestic'],
    'risk_level' => 'medium',
    'keywords' => %w[CCPA privacy consumer_rights data_protection],
    'source_url' => 'https://oag.ca.gov/privacy/ccpa',
    'tags' => %w[privacy consumer_rights data_protection]
  }
)

# Update organization compliance profiles for testing
puts 'Updating organization compliance profiles for auto-assignment testing...'

# Acme Corporation (Technology)
acme = orgs.first
acme.update!(settings: acme.settings.merge({
                                             'compliance_jurisdictions' => %w[US CA],
                                             'compliance_industries' => %w[technology software],
                                             'compliance_sectors' => %w[SaaS enterprise_software],
                                             'compliance_company_size' => 'large',
                                             'compliance_data_types' => %w[personal_data business_data],
                                             'compliance_geographic_scope' => %w[domestic international],
                                             'compliance_risk_level' => 'medium',
                                             'auto_assignment_enabled' => true,
                                             'assignment_priority_threshold' => 3
                                           }))

# Global Financial Services
gfs = orgs.second
gfs.update!(settings: gfs.settings.merge({
                                           'compliance_jurisdictions' => ['US'],
                                           'compliance_industries' => %w[financial_services banking],
                                           'compliance_sectors' => %w[investment_management consumer_finance],
                                           'compliance_company_size' => 'large',
                                           'compliance_data_types' => %w[financial_data personal_data],
                                           'compliance_geographic_scope' => %w[domestic international],
                                           'compliance_risk_level' => 'high',
                                           'auto_assignment_enabled' => true,
                                           'assignment_priority_threshold' => 5
                                         }))

# Healthcare Solutions Inc
hsi = orgs.third
hsi.update!(settings: hsi.settings.merge({
                                           'compliance_jurisdictions' => ['US'],
                                           'compliance_industries' => ['healthcare'],
                                           'compliance_sectors' => %w[healthcare_providers health_technology],
                                           'compliance_company_size' => 'medium',
                                           'compliance_data_types' => %w[health_data personal_data],
                                           'compliance_geographic_scope' => ['domestic'],
                                           'compliance_risk_level' => 'high',
                                           'auto_assignment_enabled' => true,
                                           'assignment_priority_threshold' => 4
                                         }))

puts "\n✓ Seed data creation complete!"
puts 'Created:'
puts "- #{Organization.count} organizations"
puts "- #{User.count} users"
puts "- #{Role.count} roles"
puts "- #{Permission.count} permissions"
puts "- #{Provider.count} providers"
puts "- #{ComplianceFramework.count} compliance frameworks"
puts "- #{ComplianceRequirement.count} compliance requirements"
puts "- #{ComplianceControl.count} compliance controls"
puts "- #{Document.count} documents"
puts "- #{Regulation.count} regulations"

# Verify super admin user
super_admin_user = User.find_by(email: 'admin1@example.com')
if super_admin_user
  puts "\nSuper Admin User Verification:"
  puts "- Email: #{super_admin_user.email}"
  puts "- Organization: #{super_admin_user.organization&.name || 'None'}"
  puts "- Super Admin?: #{super_admin_user.super_admin?}"
  puts "- Has Super Admin role?: #{super_admin_user.has_role?('Super Admin')}"
  puts "- All roles: #{super_admin_user.roles.pluck(:name).join(', ')}"
  puts "- Role objects: #{super_admin_user.roles.map(&:inspect).join(', ')}"
  puts "- Roles count: #{super_admin_user.roles.count}"

  # Check if roles exist in the database
  super_admin_role = Role.find_by(name: 'Super Admin', organization: nil)
  puts "- Super Admin role exists?: #{super_admin_role.present?}"
  if super_admin_role
    puts "- Super Admin role ID: #{super_admin_role.id}"
    puts "- Users with Super Admin role: #{super_admin_role.users.pluck(:email).join(', ')}"
  end
else
  puts "\n⚠️  Warning: Super admin user (admin1@example.com) not found!"
end

puts "\nDefault login credentials:"
puts 'Email: admin1@example.com'
puts 'Password: password123'

puts "✓ Created #{regulations.count} sample regulations"
puts '✓ Updated organization compliance profiles'
