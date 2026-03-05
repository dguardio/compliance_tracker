class EvidenceAgentsController < ApplicationController
  before_action -> { require_feature!(:evidence_agents) }
  before_action :set_organization
  before_action :authorize_agents

  def index
    @credentials = EvidenceAgentCredential.where(organization: @organization).order(:provider)
    @checks = EvidenceCheck.where(organization: @organization).includes(:evidence_agent_credential).order(last_run_at: :desc).limit(20)
  end

  def checks
    @checks = EvidenceCheck.where(organization: @organization)
                .includes(:evidence_agent_credential, :compliance_control)
                .order(last_run_at: :desc)
    @checks = @checks.where(last_result: params[:result]) if params[:result].present?
    @checks = @checks.failing if params[:failing] == 'true'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_agents
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
