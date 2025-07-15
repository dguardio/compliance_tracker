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
User.destroy_all
Organization.destroy_all
Role.destroy_all
Permission.destroy_all
Provider.destroy_all
ComplianceFramework.destroy_all
ComplianceRequirement.destroy_all
ComplianceControl.destroy_all
Document.destroy_all

# Create organizations
puts 'Creating organizations...'
organizations = []

organizations << Organization.create!(
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

organizations << Organization.create!(
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

organizations << Organization.create!(
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

# Create users for each organization
puts 'Creating users...'
users = []

organizations.each_with_index do |org, index|
  # Create admin user
  admin_user = User.create!(
    email: "admin#{index + 1}@example.com",
    password: 'password123',
    password_confirmation: 'password123',
    organization: org,
    settings: {
      first_name: 'Admin',
      last_name: 'User',
      job_title: 'System Administrator',
      phone: "+1-555-000#{index + 1}",
      timezone: org.settings[:timezone],
      notification_settings: {
        email: true,
        in_app: true,
        frequency: 'immediate'
      },
      ui_preferences: {
        theme: 'light',
        dashboard_layout: 'default',
        show_analytics: true
      }
    }
  )
  users << admin_user

  # Create regular users
  3.times do |i|
    user = User.create!(
      email: "user#{index + 1}_#{i + 1}@example.com",
      password: 'password123',
      password_confirmation: 'password123',
      organization: org,
      settings: {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        job_title: Faker::Job.title,
        phone: Faker::PhoneNumber.phone_number,
        timezone: org.settings[:timezone],
        notification_settings: {
          email: true,
          in_app: true,
          frequency: 'daily'
        },
        ui_preferences: {
          theme: 'light',
          dashboard_layout: 'default',
          show_analytics: true
        }
      }
    )
    users << user
  end
end

# Create global roles (available to all organizations)
puts 'Creating global roles...'
roles = {}

%w[super_admin org_admin compliance_manager compliance_analyst user].each do |role_name|
  roles[role_name] = Role.create!(
    name: role_name,
    organization: nil # Global role, not tied to any specific organization
  )
end

# Create organization-specific roles for each organization
puts 'Creating organization-specific roles...'
organizations.each do |org|
  # Create some custom roles for each organization
  org_roles = []

  org_roles << Role.create!(
    name: "#{org.name.downcase.gsub(/\s+/, '_')}_custom_role",
    organization: org
  )

  org_roles << Role.create!(
    name: "#{org.name.downcase.gsub(/\s+/, '_')}_department_head",
    organization: org
  )

  # Store org-specific roles for later use
  roles["#{org.slug}_custom"] = org_roles.first
  roles["#{org.slug}_dept_head"] = org_roles.last
end

# Create permissions for each organization
puts 'Creating permissions...'
permissions = {}

organizations.each do |org|
  org_permissions = {}

  # Use only valid actions from the Permission model
  %w[create read update destroy manage assign delegate].each do |action|
    %w[organizations users roles permissions documents compliance_frameworks compliance_requirements compliance_controls
       providers].each do |resource|
      permission_name = "#{action}_#{resource}"
      org_permissions[permission_name] = Permission.create!(
        name: permission_name,
        action: action,
        resource_type: resource.classify,
        organization: org,
        grantee_type: 'Role',
        grantee_id: roles['super_admin'].id
      )
    end
  end

  # Store permissions for this organization
  permissions[org.id] = org_permissions
end

# Assign roles to users
puts 'Assigning roles to users...'
users.each_with_index do |user, index|
  puts "  Assigning roles to user #{index + 1}: #{user.email}"

  # Assign global roles to users
  if index == 0
    puts "    Assigning super_admin role to #{user.email}"
    user.add_role(roles['super_admin'])
  elsif index % 4 == 0
    puts "    Assigning org_admin role to #{user.email}"
    user.add_role(roles['org_admin'])
  elsif index % 4 == 1
    puts "    Assigning compliance_manager role to #{user.email}"
    user.add_role(roles['compliance_manager'])
  elsif index % 4 == 2
    puts "    Assigning compliance_analyst role to #{user.email}"
    user.add_role(roles['compliance_analyst'])
  else
    puts "    Assigning user role to #{user.email}"
    user.add_role(roles['user'])
  end

  # Also assign organization-specific roles to some users
  user_org = user.organization
  next unless user_org

  # Assign custom role to every 3rd user
  if index % 3 == 0
    custom_role = roles["#{user_org.slug}_custom"]
    if custom_role
      puts "    Assigning custom role to #{user.email}"
      user.add_role(custom_role)
    end
  end

  # Assign department head role to every 5th user
  if index % 5 == 0
    dept_head_role = roles["#{user_org.slug}_dept_head"]
    if dept_head_role
      puts "    Assigning department head role to #{user.email}"
      user.add_role(dept_head_role)
    end
  end
end

# Create platform-wide providers
puts 'Creating platform-wide providers...'
platform_providers = [
  {
    name: 'Securities and Exchange Commission (SEC)',
    code: 'SEC',
    description: 'Federal securities regulator for the United States',
    website: 'https://www.sec.gov',
    jurisdiction: 'US',
    state: nil,
    country: 'United States',
    contact_info: {
      email: 'help@sec.gov',
      phone: '+1-202-551-6551'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'Financial Industry Regulatory Authority (FINRA)',
    code: 'FINRA',
    description: 'Self-regulatory organization for broker-dealers',
    website: 'https://www.finra.org',
    jurisdiction: 'US',
    state: nil,
    country: 'United States',
    contact_info: {
      email: 'support@finra.org',
      phone: '+1-301-590-6500'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'Federal Reserve Board',
    code: 'FRB',
    description: 'Central bank of the United States',
    website: 'https://www.federalreserve.gov',
    jurisdiction: 'US',
    state: nil,
    country: 'United States',
    contact_info: {
      email: 'info@federalreserve.gov',
      phone: '+1-202-452-3000'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'Office of the Comptroller of the Currency (OCC)',
    code: 'OCC',
    description: 'Federal bank regulator',
    website: 'https://www.occ.gov',
    jurisdiction: 'US',
    state: nil,
    country: 'United States',
    contact_info: {
      email: 'occ@occ.gov',
      phone: '+1-202-649-6800'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'Consumer Financial Protection Bureau (CFPB)',
    code: 'CFPB',
    description: 'Consumer financial protection regulator',
    website: 'https://www.consumerfinance.gov',
    jurisdiction: 'US',
    state: nil,
    country: 'United States',
    contact_info: {
      email: 'info@consumerfinance.gov',
      phone: '+1-855-411-2372'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'European Banking Authority (EBA)',
    code: 'EBA',
    description: 'EU banking regulator',
    website: 'https://www.eba.europa.eu',
    jurisdiction: 'EU',
    state: nil,
    country: 'France',
    contact_info: {
      email: 'info@eba.europa.eu',
      phone: '+33-1-86-52-70-00'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'Financial Conduct Authority (FCA)',
    code: 'FCA',
    description: 'UK financial services regulator',
    website: 'https://www.fca.org.uk',
    jurisdiction: 'UK',
    state: nil,
    country: 'United Kingdom',
    contact_info: {
      email: 'consumer.queries@fca.org.uk',
      phone: '+44-20-7066-1000'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'Office of the Superintendent of Financial Institutions (OSFI)',
    code: 'OSFI',
    description: 'Canadian financial regulator',
    website: 'https://www.osfi-bsif.gc.ca',
    jurisdiction: 'CA',
    state: nil,
    country: 'Canada',
    contact_info: {
      email: 'information@osfi-bsif.gc.ca',
      phone: '+1-613-990-7788'
    },
    provider_type: 'platform_wide',
    status: 'active'
  },
  {
    name: 'Australian Prudential Regulation Authority (APRA)',
    code: 'APRA',
    description: 'Australian financial regulator',
    website: 'https://www.apra.gov.au',
    jurisdiction: 'AU',
    state: nil,
    country: 'Australia',
    contact_info: {
      email: 'info@apra.gov.au',
      phone: '+61-2-9210-3000'
    },
    provider_type: 'platform_wide',
    status: 'active'
  }
]

# Create platform-wide providers without tenant scoping
Provider.unscoped do
  platform_providers.each do |provider_data|
    Provider.create!(provider_data.merge(organization_id: nil))
  end
end

# Create organization-specific providers
puts 'Creating organization-specific providers...'
organizations.each do |org|
  org_provider = Provider.create!(
    name: "#{org.name} Internal Compliance",
    code: "#{org.name.upcase.gsub(/\s+/, '')}_COMPLIANCE".first(20),
    description: "Internal compliance department for #{org.name}",
    website: org.settings[:website],
    jurisdiction: org.settings[:jurisdiction].presence || 'US',
    state: org.settings[:state],
    country: org.settings[:country].presence || 'United States',
    contact_info: {
      email: "compliance@#{org.name.downcase.gsub(/\s+/, '')}.com",
      phone: org.settings[:contact_phone]
    },
    provider_type: 'organization_specific',
    organization: org,
    status: 'active'
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
    organization: organizations.first,
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
    organization: organizations.second,
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
    organization: organizations.third,
    settings: {
      framework_type: 'supervision',
      effective_date: Date.new(2015, 3, 1),
      industry_scope: %w[broker_dealers securities],
      review_frequency: 'monthly'
    }
  )
end

# GDPR Framework (Note: Using 'Guidance' instead of 'Regulation' since 'Regulation' is not in the enum)
eba_provider = Provider.find_by(code: 'EBA')
if eba_provider
  frameworks << ComplianceFramework.create!(
    name: 'General Data Protection Regulation (GDPR)',
    slug: 'gdpr',
    description: 'The GDPR is a regulation in EU law on data protection and privacy in the European Union and the European Economic Area. It also addresses the transfer of personal data outside the EU and EEA areas.',
    version: '1.0',
    jurisdiction: 'EU',
    provider: eba_provider,
    issuance_type: 'Guidance', # Changed from 'Regulation' to 'Guidance' since 'Regulation' is not in the enum
    publication_date: Date.new(2016, 4, 27),
    provider_url: 'https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX%3A32016R0679',
    enforcement_date: Date.new(2018, 5, 25),
    potentially_impacted_departments: 'IT, Legal, Compliance, HR, Marketing',
    status: 'active',
    organization: organizations.first, # Back to first org since we only have 3 orgs
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
organizations.each do |org|
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

# Verify super admin user
super_admin_user = User.find_by(email: 'admin1@example.com')
if super_admin_user
  puts "\nSuper Admin User Verification:"
  puts "- Email: #{super_admin_user.email}"
  puts "- Super Admin?: #{super_admin_user.super_admin?}"
  puts "- Roles: #{super_admin_user.roles.pluck(:name).join(', ')}"
  puts "- Organization: #{super_admin_user.organization&.name || 'None'}"
else
  puts "\n⚠️  Warning: Super admin user (admin1@example.com) not found!"
end

puts "\nDefault login credentials:"
puts 'Email: admin1@example.com'
puts 'Password: password123'
