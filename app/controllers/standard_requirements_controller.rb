class StandardRequirementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_context

  def index
    @standard_requirements = StandardRequirement.all.limit(50)
  end

  def search
    query = params[:q]
    @results = []

    if query.present?
      # Generate embedding for the user's query
      query_embedding = Ai::EmbeddingService.generate(query)
      
      if query_embedding
        # Perform vector search
        # Using the scope .related_to(embedding) which uses nearest_neighbors
        results_scope = StandardRequirement.related_to(query_embedding)
        
        # Filter by category if provided? (Not implemented yet, but good for future)
        
        @results = results_scope.limit(10)
      else
        flash.now[:alert] = "Could not generate results for that query."
      end
    end

    render :index
  end

  def adopt
    @standard_requirement = StandardRequirement.find(params[:id])
    
    unless @compliance_framework
      redirect_to standard_requirements_path, alert: "No compliance framework selected for adoption."
      return
    end

    # Create the compliance requirement from the standard
    @compliance_requirement = @compliance_framework.compliance_requirements.build(
      name: @standard_requirement.name,
      description: @standard_requirement.description,
      standard_requirement: @standard_requirement, # Link back to source
      requirement_type: :legal_basis, # Default, user might need to change
      priority: :medium,
      status: :draft,
      organization: @organization
    )

    if @compliance_requirement.save
      # Ensure the Regulation is linked to this Framework
      if @standard_requirement.regulation
        OrganizationRegulation.find_or_create_by(
          organization: @organization,
          regulation: @standard_requirement.regulation
        ) do |org_reg|
          org_reg.compliance_framework = @compliance_framework
          org_reg.status = 'active'
          org_reg.priority = 1
        end
        # Note: If it already existed, we might want to update the framework if it was nil? 
        # But for now, let's assume one main framework per regulation instantiation.
      end

      redirect_to organization_compliance_framework_path(@organization, @compliance_framework), 
                  notice: "Standard requirement adopted successfully."
    else
      redirect_to search_standard_requirements_path(q: params[:q], organization_id: @organization.id, compliance_framework_id: @compliance_framework.id), 
                  alert: "Failed to adopt requirement: #{@compliance_requirement.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_context
    if params[:organization_id].present?
      @organization = Organization.find(params[:organization_id])
      # Ensure user has access? ApplicationController usually handles tenant check if current_user.org matches
      # But we should verify if implicit authorization is enough or if we need Pundit
      authorize_organization_access if @organization
    end

    if @organization && params[:compliance_framework_id].present?
      @compliance_framework = @organization.compliance_frameworks.find_by(id: params[:compliance_framework_id])
    end
  end

  def authorize_organization_access
    # Basic check: User must belong to org or be super admin
    unless current_user.super_admin? || current_user.organization_id == @organization.id
      redirect_to root_path, alert: "Not authorized."
    end
  end
end
