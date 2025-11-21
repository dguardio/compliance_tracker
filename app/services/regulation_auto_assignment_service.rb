# frozen_string_literal: true

# Service to automatically assign regulations to organizations based on their compliance profile.
class RegulationAutoAssignmentService
  # @param organization [Organization] The organization to update assignments for.
  # @return [Array<Regulation>] The list of newly assigned regulations.
  def update_organization_assignments(organization)
    Rails.logger.info "Updating regulation assignments for organization: #{organization.name}"
    
    return [] unless organization.auto_assignment_enabled? && organization.has_compliance_profile?

    should_be_assigned_ids = find_matching_regulations(organization).pluck(:id)
    currently_assigned_ids = organization.organization_regulations.pluck(:regulation_id)
    newly_assigned_regulations = []

    # Assign new regulations
    new_ids = should_be_assigned_ids - currently_assigned_ids
    if new_ids.any?
      Rails.logger.info "Assigning #{new_ids.count} new regulations to #{organization.name}."
      new_regulations = Regulation.where(id: new_ids)
      new_regulations.each do |reg|
        organization.organization_regulations.create(
          regulation: reg,
          status: 'pending',
          notes: 'Automatically assigned based on updated compliance profile.'
        )
        newly_assigned_regulations << reg
      end
    end

    # Deactivate old regulations that no longer match
    deactivated_ids = currently_assigned_ids - should_be_assigned_ids
    if deactivated_ids.any?
      Rails.logger.info "Deactivating #{deactivated_ids.count} regulations for #{organization.name}."
      organization.organization_regulations.where(regulation_id: deactivated_ids).update_all(status: 'archived')
    end
    
    newly_assigned_regulations
  end

  # Main entry point to process a single new regulation and assign it to all
  # matching organizations. This is called after a new regulation is created and processed.
  #
  # @param regulation [Regulation] The new regulation to assign.
  # @return [Array<Organization>] The list of organizations that were assigned the regulation.
  def process_new_regulation(regulation)
    Rails.logger.info "Processing new regulation for auto-assignment: #{regulation.title}"
    
    matching_orgs = find_matching_organizations(regulation)
    
    Rails.logger.info "Found #{matching_orgs.count} matching organizations for regulation '#{regulation.title}'."

    assigned_orgs = []
    matching_orgs.each do |organization|
      org_reg, created = OrganizationRegulation.find_or_create_by(
        organization: organization,
        regulation: regulation
      ) do |new_org_reg|
        new_org_reg.status = 'pending'
        new_org_reg.notes = 'Automatically assigned based on new regulation.'
      end
      
      if created
        Rails.logger.info "Assigned regulation to #{organization.name}."
        assigned_orgs << organization
      elsif org_reg.errors.any?
        Rails.logger.error "Failed to assign regulation #{regulation.id} to #{organization.name}: #{org_reg.errors.full_messages.join(', ')}"
      end
    end
    
    assigned_orgs
  end

  private

  # Finds regulations that match an organization's compliance profile.
  #
  # @param organization [Organization] The organization.
  # @return [ActiveRecord::Relation<Regulation>] A relation of matching regulations.
  def find_matching_regulations(organization)
    profile = organization.compliance_profile
    
    # Start with a base scope
    scope = Regulation.where(status: 'active') # Assuming we only assign active regulations

    # Match jurisdiction
    if profile[:jurisdictions].any?
      scope = scope.where(jurisdiction: profile[:jurisdictions])
    end

    # Match industries using JSONB array overlap operator
    if profile[:industries].any?
      scope = scope.where("metadata->'potential_impacted_industries' ?| array[:industries]", industries: profile[:industries])
    end
    
    # Match keywords (simple text search for now)
    if profile[:keywords].any?
      keyword_query = profile[:keywords].map { |kw| "full_text->>'extracted_content' ILIKE ?" }.join(' OR ')
      keyword_values = profile[:keywords].map { |kw| "%#{kw}%" }
      scope = scope.where(keyword_query, *keyword_values)
    end

    # Handle exclusion terms
    if profile[:exclusion_terms].any?
      exclusion_query = profile[:exclusion_terms].map { |term| "full_text->>'extracted_content' NOT ILIKE ?" }.join(' AND ')
      exclusion_values = profile[:exclusion_terms].map { |term| "%#{term}%" }
      scope = scope.where(exclusion_query, *exclusion_values)
    end

    scope
  end

  # Finds organizations whose compliance profile matches a regulation's attributes.
  #
  # @param regulation [Regulation] The regulation.
  # @return [ActiveRecord::Relation<Organization>] A relation of matching organizations.
  def find_matching_organizations(regulation)
    # Start with organizations that have auto-assignment enabled
    scope = Organization.active.where("settings->>'auto_assignment_enabled' = 'true'")

    # Match jurisdiction
    scope = scope.where("settings->'compliance_jurisdictions' ? :jurisdiction", jurisdiction: regulation.jurisdiction)

    # Match industries
    impacted_industries = regulation.metadata['potential_impacted_industries']
    if impacted_industries.present? && impacted_industries.any?
      scope = scope.where("settings->'compliance_industries' ?| array[:industries]", industries: impacted_industries)
    end

    scope
  end
end