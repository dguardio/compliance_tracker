class PolicyLinksController < ApplicationController
  before_action -> { require_feature!(:policies) }
  before_action :set_organization
  before_action :set_policy

  def new
    authorize @policy, :edit?
    @policy_link = @policy.policy_links.new
    @linkable_type = params[:linkable_type]
    
    case @linkable_type
    when 'Regulation'
      # Tenants can see all regulations? Or only assigned ones? 
      # For now, let's assume they can see all Regulations in the system or just applicable ones.
      # Let's stick to 'Regulation.all' for simplicity or 'current_organization.applicable_regulations' if that exists.
      @linkables = Regulation.all.order(:title) 
    when 'ComplianceControl'
      @linkables = @organization.compliance_controls.active.order(:name)
    when 'RiskAssessment'
      @linkables = @organization.risk_assessments.active.order(:name)
    else
      redirect_to organization_policy_path(@organization, @policy), alert: "Invalid link type."
    end
  end

  def create
    authorize @policy, :edit?
    @policy_link = @policy.policy_links.new(policy_link_params)

    if @policy_link.save
      redirect_to organization_policy_path(@organization, @policy), notice: 'Link was successfully added.'
    else
      @linkable_type = @policy_link.linkable_type
      case @linkable_type
      when 'Regulation'
        @linkables = Regulation.all.order(:title)
      when 'ComplianceControl'
        @linkables = @organization.compliance_controls.active.order(:name)
      when 'RiskAssessment'
        @linkables = @organization.risk_assessments.active.order(:name)
      end
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @policy, :edit?
    @policy_link = @policy.policy_links.find(params[:id])
    @policy_link.destroy
    redirect_to organization_policy_path(@organization, @policy), notice: 'Link was successfully removed.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_policy
    @policy = @organization.policies.find(params[:policy_id])
  end

  def policy_link_params
    params.require(:policy_link).permit(:linkable_type, :linkable_id, :citation, :notes)
  end
end
