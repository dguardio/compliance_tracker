class ProvidersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provider, only: [:show, :edit, :update, :destroy]
  before_action :authorize_provider, except: [:index, :new, :create]

  def index
    # Show both platform-wide and organization-specific providers
    @providers = Provider.available_for_organization(current_organization)
                        .includes(:compliance_frameworks)
                        .order(:name)
                        .page(params[:page])
                        .per(20)

    # Apply filters
    @providers = @providers.by_jurisdiction(params[:jurisdiction]) if params[:jurisdiction].present?
    @providers = @providers.by_country(params[:country]) if params[:country].present?
    @providers = @providers.where(status: params[:status]) if params[:status].present?
    @providers = @providers.where(provider_type: params[:provider_type]) if params[:provider_type].present?

    # Get filter options
    @jurisdictions = Provider.available_for_organization(current_organization).distinct.pluck(:jurisdiction).compact.sort
    @countries = Provider.available_for_organization(current_organization).distinct.pluck(:country).compact.sort
    @provider_types = Provider.provider_types.keys
  end

  def show
    @compliance_frameworks = @provider.compliance_frameworks
                                     .includes(:compliance_requirements)
                                     .order(created_at: :desc)
                                     .page(params[:page])
                                     .per(10)
  end

  def new
    @provider = Provider.new
    @provider.organization = current_organization unless current_user.super_admin?
  end

  def create
    @provider = Provider.new(provider_params)
    
    # Set organization for non-super admins
    unless current_user.super_admin?
      @provider.organization = current_organization
    end

    if @provider.save
      redirect_to @provider, notice: 'Provider was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    unless @provider.can_be_edited_by?(current_user)
      redirect_to @provider, alert: 'You do not have permission to edit this provider.'
      return
    end
  end

  def update
    unless @provider.can_be_edited_by?(current_user)
      redirect_to @provider, alert: 'You do not have permission to edit this provider.'
      return
    end

    if @provider.update(provider_params)
      redirect_to @provider, notice: 'Provider was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @provider.can_be_deleted_by?(current_user)
      redirect_to @provider, alert: 'You do not have permission to delete this provider.'
      return
    end

    if @provider.compliance_frameworks.any?
      redirect_to @provider, alert: 'Cannot delete provider with associated compliance frameworks.'
    else
      @provider.destroy
      redirect_to providers_path, notice: 'Provider was successfully deleted.'
    end
  end

  def recommendations
    @recommendation_service = ProviderRecommendationService.new(current_organization)
    @recommendations = @recommendation_service.recommendations_with_explanations
    @essential_providers = @recommendation_service.essential_providers
    @industry_providers = @recommendation_service.industry_specific_providers
  end

  def auto_assign
    @recommendation_service = ProviderRecommendationService.new(current_organization)
    
    begin
      assigned_count = @recommendation_service.auto_assign_providers
      redirect_to providers_path, notice: "Successfully auto-assigned #{assigned_count} providers to your organization."
    rescue => e
      redirect_to recommendations_providers_path, alert: "Error auto-assigning providers: #{e.message}"
    end
  end

  def bulk_assign
    provider_ids = params[:provider_ids] || []
    
    if provider_ids.empty?
      redirect_to recommendations_providers_path, alert: 'Please select at least one provider to assign.'
      return
    end
    
    assigned_count = 0
    platform_providers = Provider.platform_wide.where(id: provider_ids)
    
    platform_providers.each do |platform_provider|
      next if current_organization.providers.exists?(code: platform_provider.code)
      
      current_organization.providers.create!(
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
      
      assigned_count += 1
    end
    
    redirect_to providers_path, notice: "Successfully assigned #{assigned_count} providers to your organization."
  end

  private

  def set_provider
    @provider = Provider.available_for_organization(current_organization).find(params[:id])
  end

  def authorize_provider
    # Add authorization logic here if needed
    # For now, allow all authenticated users to view
  end

  def provider_params
    permitted_params = [
      :name, :code, :description, :website, :jurisdiction, :state, :country, :status,
      contact_info: [:email, :phone, :address, :primary_contact, :secondary_contact],
      settings: [:provider_category, :regulatory_authority, :enforcement_powers, 
                 :reporting_requirements, :filing_deadlines, :fee_structure, 
                 :compliance_areas, :custom_fields]
    ]
    
    # Only super admins can set organization_id
    permitted_params << :organization_id if current_user.super_admin?
    
    params.require(:provider).permit(permitted_params)
  end
end
