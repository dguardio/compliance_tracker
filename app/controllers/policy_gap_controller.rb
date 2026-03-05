class PolicyGapController < ApplicationController
  before_action -> { require_feature!(:policy_gap_analysis) }
  before_action :set_organization
  before_action :authorize_policy_gap

  def index
    @service = PolicyGapAnalysisService.new(@organization)
    @framework_summary = @service.all_frameworks_summary
  end

  def analyze
    @framework = ComplianceFramework.find(params[:framework_id])
    @service = PolicyGapAnalysisService.new(@organization)
    @result = @service.analyze(@framework)
  end

  def draft
    framework = ComplianceFramework.find(params[:framework_id])
    requirement = ComplianceRequirement.find(params[:requirement_id])
    service = PolicyGapAnalysisService.new(@organization)

    draft = service.draft_policy(requirement, framework)

    # Create the policy as a draft
    policy = @organization.policies.new(
      title: draft[:title],
      description: draft[:description],
      body: draft[:body],
      status: :draft
    )

    if policy.save
      # Create the policy link to the requirement
      PolicyLink.create(
        policy: policy,
        linkable: requirement
      )
      redirect_to organization_policy_path(@organization, policy),
                  notice: "Draft policy '#{draft[:title]}' created. Please review and customize."
    else
      redirect_to organization_policy_gap_analyze_path(@organization, framework_id: framework.id),
                  alert: "Failed to create draft: #{policy.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_policy_gap
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
