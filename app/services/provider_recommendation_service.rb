class ProviderRecommendationService
  def initialize(organization)
    @organization = organization
  end

  # Get recommended providers based on organization characteristics
  def recommended_providers
    providers = Provider.platform_wide.active

    # Filter by jurisdiction
    providers = filter_by_jurisdiction(providers)
    
    # Filter by industry
    providers = filter_by_industry(providers)
    
    # Filter by organization size/type
    providers = filter_by_organization_type(providers)
    
    # Add priority scoring
    providers = add_priority_scoring(providers)
    
    providers.order('priority_score DESC, name ASC')
  end

  # Get essential providers that most organizations need
  def essential_providers
    essential_codes = case @organization.settings[:jurisdiction]
    when 'US'
      %w[IRS SEC FTC]
    when 'EU'
      %w[GDPR_Authority EBA EIOPA ESMA]
    when 'UK'
      %w[FCA PRA ICO]
    else
      %w[IRS SEC FTC] # Default to US providers
    end

    Provider.platform_wide.active.where(code: essential_codes)
  end

  # Get industry-specific providers
  def industry_specific_providers
    industry = @organization.settings[:industry]&.downcase
    
    case industry
    when 'banking', 'financial_services'
      banking_providers
    when 'insurance'
      insurance_providers
    when 'healthcare'
      healthcare_providers
    when 'technology', 'fintech'
      technology_providers
    when 'real_estate'
      real_estate_providers
    when 'manufacturing'
      manufacturing_providers
    when 'retail'
      retail_providers
    else
      general_providers
    end
  end

  # Auto-assign providers to organization
  def auto_assign_providers
    recommended = recommended_providers.limit(10) # Limit to top 10 recommendations
    
    # Create organization-specific copies of platform-wide providers
    recommended.each do |platform_provider|
      next if @organization.providers.exists?(code: platform_provider.code)
      
      # Create organization-specific copy
      org_provider = @organization.providers.create!(
        name: platform_provider.name,
        code: platform_provider.code,
        description: platform_provider.description,
        website: platform_provider.website,
        jurisdiction: platform_provider.jurisdiction,
        state: platform_provider.state,
        country: platform_provider.country,
        contact_info: platform_provider.contact_info,
        settings: platform_provider.settings,
        status: :active
      )
      
      Rails.logger.info "Auto-assigned provider #{org_provider.name} to organization #{@organization.name}"
    end
    
    recommended.count
  end

  # Get provider recommendations with explanations
  def recommendations_with_explanations
    recommendations = []
    
    recommended_providers.each do |provider|
      explanation = generate_explanation(provider)
      recommendations << {
        provider: provider,
        explanation: explanation,
        priority_score: provider.priority_score || 0
      }
    end
    
    recommendations.sort_by { |r| -r[:priority_score] }
  end

  private

  def filter_by_jurisdiction(providers)
    jurisdiction = @organization.settings[:jurisdiction]
    return providers unless jurisdiction.present?
    
    case jurisdiction.downcase
    when 'us', 'united states'
      providers.where(country: 'United States')
    when 'eu', 'european union'
      providers.where(country: ['Germany', 'France', 'Italy', 'Spain', 'Netherlands'])
    when 'uk', 'united kingdom'
      providers.where(country: 'United Kingdom')
    when 'canada'
      providers.where(country: 'Canada')
    else
      providers.where("LOWER(country) LIKE ? OR LOWER(jurisdiction) LIKE ?", 
                     "%#{jurisdiction.downcase}%", "%#{jurisdiction.downcase}%")
    end
  end

  def filter_by_industry(providers)
    industry = @organization.settings[:industry]&.downcase
    return providers unless industry.present?
    
    # Filter by compliance areas that match the industry
    industry_keywords = industry_keywords_for(industry)
    
    providers.where("settings->>'compliance_areas' ?| array[:keywords]", keywords: industry_keywords)
  end

  def filter_by_organization_type(providers)
    # Add logic based on organization size, type, etc.
    # For now, return all providers
    providers
  end

  def add_priority_scoring(providers)
    providers.each do |provider|
      score = calculate_priority_score(provider)
      provider.define_singleton_method(:priority_score) { score }
    end
  end

  def calculate_priority_score(provider)
    score = 0
    
    # Base score for regulatory authorities
    score += 10 if provider.is_regulatory_authority?
    
    # Score based on jurisdiction match
    if jurisdiction_matches?(provider)
      score += 20
    end
    
    # Score based on industry relevance
    if industry_relevant?(provider)
      score += 15
    end
    
    # Score based on enforcement powers
    score += 5 if provider.has_enforcement_powers?
    
    # Score based on organization size relevance
    score += calculate_size_relevance_score(provider)
    
    score
  end

  def jurisdiction_matches?(provider)
    org_jurisdiction = @organization.settings[:jurisdiction]&.downcase
    provider_jurisdiction = provider.jurisdiction&.downcase
    
    return false unless org_jurisdiction.present? && provider_jurisdiction.present?
    
    org_jurisdiction == provider_jurisdiction || 
    provider_jurisdiction.include?(org_jurisdiction) ||
    org_jurisdiction.include?(provider_jurisdiction)
  end

  def industry_relevant?(provider)
    industry = @organization.settings[:industry]&.downcase
    return false unless industry.present?
    
    compliance_areas = provider.compliance_areas_list.map(&:downcase)
    industry_keywords = industry_keywords_for(industry)
    
    (compliance_areas & industry_keywords).any?
  end

  def calculate_size_relevance_score(provider)
    # Add logic based on organization size
    # For now, return 0
    0
  end

  def industry_keywords_for(industry)
    case industry
    when 'banking', 'financial_services'
      %w[banking financial consumer protection fair lending deposit insurance]
    when 'insurance'
      %w[insurance risk management claims underwriting]
    when 'healthcare'
      %w[healthcare medical privacy hipaa patient data]
    when 'technology', 'fintech'
      %w[technology cybersecurity data privacy fintech digital payments]
    when 'real_estate'
      %w[real estate mortgage housing fair housing]
    when 'manufacturing'
      %w[manufacturing workplace safety labor standards]
    when 'retail'
      %w[retail consumer protection fair trade]
    else
      %w[consumer protection data privacy workplace safety]
    end
  end

  def generate_explanation(provider)
    reasons = []
    
    if provider.is_regulatory_authority?
      reasons << "Regulatory authority for your jurisdiction"
    end
    
    if jurisdiction_matches?(provider)
      reasons << "Matches your organization's jurisdiction"
    end
    
    if industry_relevant?(provider)
      reasons << "Relevant to your industry (#{@organization.settings[:industry]})"
    end
    
    if provider.has_enforcement_powers?
      reasons << "Has enforcement powers"
    end
    
    reasons.any? ? reasons.join(". ") : "General compliance provider"
  end

  def banking_providers
    Provider.platform_wide.active.where(code: %w[FDIC OCC FRB CFPB FFIEC FinCEN])
  end

  def insurance_providers
    Provider.platform_wide.active.where(code: %w[NAIC DOL EEOC])
  end

  def healthcare_providers
    Provider.platform_wide.active.where(code: %w[HHS OCR DOL EEOC])
  end

  def technology_providers
    Provider.platform_wide.active.where(code: %w[FTC SEC CFPB])
  end

  def real_estate_providers
    Provider.platform_wide.active.where(code: %w[HUD CFPB FTC])
  end

  def manufacturing_providers
    Provider.platform_wide.active.where(code: %w[DOL EPA OSHA])
  end

  def retail_providers
    Provider.platform_wide.active.where(code: %w[FTC CFPB DOL])
  end

  def general_providers
    Provider.platform_wide.active.where(code: %w[IRS FTC DOL])
  end
end 