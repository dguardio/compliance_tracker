class ExternalIntegrationsController < ApplicationController
  before_action -> { require_feature!(:external_integrations) }
  before_action :set_organization
  before_action :authorize_integrations

  def index
    @integrations = ExternalIntegration.where(organization: @organization).order(:provider)
    @recent_tickets = ExternalTicket.where(organization: @organization).recent.limit(20)
  end

  def show
    @integration = ExternalIntegration.where(organization: @organization).find(params[:id])
    @tickets = @integration.external_tickets.recent
  end

  def new
    @integration = ExternalIntegration.new
  end

  def create
    @integration = @organization.external_integrations.new(integration_params)
    if @integration.save
      redirect_to organization_external_integration_path(@organization, @integration),
                  notice: "#{@integration.provider_info[:name]} integration created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def sync
    integration = ExternalIntegration.where(organization: @organization).find(params[:id])
    # In production, this would call the adapter service
    integration.update!(last_synced_at: Time.current)
    redirect_to organization_external_integration_path(@organization, integration),
                notice: 'Sync triggered. Tickets will update shortly.'
  end

  def create_ticket
    integration = ExternalIntegration.where(organization: @organization).find(params[:id])
    finding = Finding.find_by(id: params[:finding_id])
    incident = Incident.find_by(id: params[:incident_id])

    ticket = ExternalTicket.create!(
      external_integration: integration,
      organization: @organization,
      finding: finding,
      incident: incident,
      external_id: "SYNC-#{SecureRandom.hex(4).upcase}",
      external_url: "#{integration.base_url}/ticket/SYNC-#{SecureRandom.hex(4).upcase}",
      external_status: 'created',
      last_synced_at: Time.current
    )

    source_name = finding&.title || incident&.title || 'item'
    redirect_back fallback_location: organization_external_integration_path(@organization, integration),
                  notice: "Ticket created for '#{source_name}'."
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def integration_params
    params.require(:external_integration).permit(:provider, :label, :status,
                                                  config: [:base_url, :project_key])
  end

  def authorize_integrations
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
