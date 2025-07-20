class RegulationAutoAssignmentService
  attr_reader :organization, :regulation

  def initialize(organization = nil, regulation = nil)
    @organization = organization
    @regulation = regulation
  end

  # Auto-assign regulations to a specific organization
  def assign_to_organization(organization)
    @organization = organization
    return unless organization.auto_assignment_enabled?
    return unless organization.has_compliance_profile?

    matching_regulations = find_matching_regulations(organization)

    matching_regulations.each do |regulation|
      next if already_assigned?(organization, regulation)

      priority = calculate_priority(organization, regulation)
      next if priority < organization.assignment_priority_threshold

      create_assignment(organization, regulation, priority)
    end
  end

  # Auto-assign a specific regulation to all matching organizations
  def assign_regulation_to_organizations(regulation)
    @regulation = regulation
    matching_organizations = find_matching_organizations(regulation)

    matching_organizations.each do |organization|
      next unless organization.auto_assignment_enabled?
      next if already_assigned?(organization, regulation)

      priority = calculate_priority(organization, regulation)
      next if priority < organization.assignment_priority_threshold

      create_assignment(organization, regulation, priority)
    end
  end

  # Bulk auto-assignment for all organizations and regulations
  def bulk_auto_assignment
    Organization.active.find_each do |organization|
      assign_to_organization(organization)
    end
  end

  # Update assignments when organization profile changes
  def update_organization_assignments(organization)
    @organization = organization

    # Remove assignments that no longer match
    remove_non_matching_assignments(organization)

    # Add new matching assignments
    assign_to_organization(organization)
  end

  private

  def find_matching_regulations(organization)
    profile = organization.compliance_profile

    Regulation.active.where(
      jurisdiction: profile[:jurisdictions]
    ).or(
      Regulation.active.where("metadata->>'industries' ?| array[:industries]", industries: profile[:industries])
    ).or(
      Regulation.active.where("metadata->>'sectors' ?| array[:sectors]", sectors: profile[:sectors])
    ).or(
      Regulation.active.where("metadata->>'data_types' ?| array[:data_types]", data_types: profile[:data_types])
    ).or(
      Regulation.active.where("metadata->>'geographic_scope' ?| array[:geographic_scope]",
                              geographic_scope: profile[:geographic_scope])
    ).distinct
  end

  def find_matching_organizations(regulation)
    Organization.active.select do |org|
      profile = org.compliance_profile

      # Check jurisdiction match
      jurisdiction_match = profile[:jurisdictions].include?(regulation.jurisdiction)

      # Check industry match
      regulation_industries = regulation.metadata&.dig('industries') || []
      industry_match = (profile[:industries] & regulation_industries).any?

      # Check sector match
      regulation_sectors = regulation.metadata&.dig('sectors') || []
      sector_match = (profile[:sectors] & regulation_sectors).any?

      # Check data type match
      regulation_data_types = regulation.metadata&.dig('data_types') || []
      data_type_match = (profile[:data_types] & regulation_data_types).any?

      # Check geographic scope match
      regulation_geographic_scope = regulation.metadata&.dig('geographic_scope') || []
      geographic_match = (profile[:geographic_scope] & regulation_geographic_scope).any?

      jurisdiction_match || industry_match || sector_match || data_type_match || geographic_match
    end
  end

  def calculate_priority(organization, regulation)
    profile = organization.compliance_profile
    priority = 0

    # Jurisdiction match (highest weight)
    priority += 10 if profile[:jurisdictions].include?(regulation.jurisdiction)

    # Industry match
    regulation_industries = regulation.metadata&.dig('industries') || []
    priority += 8 if (profile[:industries] & regulation_industries).any?

    # Sector match
    regulation_sectors = regulation.metadata&.dig('sectors') || []
    priority += 6 if (profile[:sectors] & regulation_sectors).any?

    # Data type match
    regulation_data_types = regulation.metadata&.dig('data_types') || []
    priority += 4 if (profile[:data_types] & regulation_data_types).any?

    # Geographic scope match
    regulation_geographic_scope = regulation.metadata&.dig('geographic_scope') || []
    priority += 3 if (profile[:geographic_scope] & regulation_geographic_scope).any?

    # Risk level alignment
    priority += 2 if profile[:risk_level] == regulation.metadata&.dig('risk_level')

    # Company size consideration
    priority += 1 if regulation.metadata&.dig('company_size')&.include?(profile[:company_size])

    # Keyword matching
    regulation_keywords = regulation.metadata&.dig('keywords') || []
    keyword_matches = (profile[:keywords] & regulation_keywords).count
    priority += keyword_matches

    # Exclusion terms (negative priority)
    exclusion_matches = (profile[:exclusion_terms] & regulation_keywords).count
    priority -= exclusion_matches * 2

    [priority, 0].max # Ensure priority is not negative
  end

  def already_assigned?(organization, regulation)
    OrganizationRegulation.exists?(organization: organization, regulation: regulation)
  end

  def create_assignment(organization, regulation, priority)
    OrganizationRegulation.create!(
      organization: organization,
      regulation: regulation,
      priority: priority,
      status: 'pending',
      assigned_at: Time.current,
      assigned_by: nil, # Auto-assigned
      notes: 'Auto-assigned based on compliance profile matching'
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create regulation assignment: #{e.message}"
  end

  def remove_non_matching_assignments(organization)
    current_assignments = organization.organization_regulations

    current_assignments.each do |assignment|
      regulation = assignment.regulation
      priority = calculate_priority(organization, regulation)

      next unless priority < organization.assignment_priority_threshold

      assignment.update!(
        status: 'inactive',
        notes: 'Auto-removed due to profile changes'
      )
    end
  end
end
