class HarmonizationController < ApplicationController
  before_action -> { require_feature!(:cross_framework_harmonization) }
  before_action :set_organization
  before_action :authorize_harmonization

  def index
    @frameworks = @organization.compliance_frameworks
    @service = HarmonizationService.new(@organization)
    @overlap_count = @service.detect_overlap.size
  end

  def matrix
    framework_ids = params[:framework_ids]&.map(&:to_i) || @organization.compliance_frameworks.pluck(:id)
    @service = HarmonizationService.new(@organization)
    @result = @service.generate_matrix(framework_ids)
    @frameworks = @organization.compliance_frameworks
  end

  def delta
    @service = HarmonizationService.new(@organization)
    @result = @service.analyze_delta(params[:framework_id])
    @frameworks = @organization.compliance_frameworks
  end

  def suggestions
    @service = HarmonizationService.new(@organization)
    @suggestions = @service.suggest_extensions
  end

  def create_mapping
    mapping = FrameworkMapping.new(mapping_params)
    mapping.organization = @organization

    if mapping.save
      redirect_back fallback_location: organization_harmonization_matrix_path(@organization),
                    notice: 'Mapping created successfully.'
    else
      redirect_back fallback_location: organization_harmonization_matrix_path(@organization),
                    alert: "Failed to create mapping: #{mapping.errors.full_messages.join(', ')}"
    end
  end

  def destroy_mapping
    mapping = FrameworkMapping.where(organization: @organization).find(params[:mapping_id])
    mapping.destroy
    redirect_back fallback_location: organization_harmonization_matrix_path(@organization),
                  notice: 'Mapping removed.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def mapping_params
    params.require(:framework_mapping).permit(:source_requirement_id, :target_requirement_id, :mapping_type, :confidence, :rationale)
  end

  def authorize_harmonization
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
