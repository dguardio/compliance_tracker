class AttestationCampaignsController < ApplicationController
  before_action -> { require_feature!(:policy_attestation) }
  before_action :set_organization
  before_action :set_campaign, only: %i[show edit update destroy launch close]
  before_action :authorize_campaign

  def index
    @campaigns = @organization.attestation_campaigns.includes(:policy, :created_by)
    @campaigns = @campaigns.where(status: params[:status]) if params[:status].present?
    @campaigns = @campaigns.order(created_at: :desc)

    @stats = {
      total: @organization.attestation_campaigns.count,
      active: @organization.attestation_campaigns.status_active.count,
      overdue: @organization.attestation_campaigns.overdue.count,
      avg_completion: calculate_avg_completion
    }
  end

  def show
    @attestations = @campaign.attestations.includes(:user).order(:status, :attested_at)
  end

  def new
    @campaign = @organization.attestation_campaigns.build
    @policies = @organization.policies.active
  end

  def create
    @campaign = @organization.attestation_campaigns.build(campaign_params)
    @campaign.created_by = current_user

    if @campaign.save
      redirect_to organization_attestation_campaign_path(@organization, @campaign),
                  notice: 'Attestation campaign was successfully created.'
    else
      @policies = @organization.policies.active
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @policies = @organization.policies.active
  end

  def update
    if @campaign.update(campaign_params)
      redirect_to organization_attestation_campaign_path(@organization, @campaign),
                  notice: 'Campaign updated.'
    else
      @policies = @organization.policies.active
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @campaign.destroy
    redirect_to organization_attestation_campaigns_path(@organization),
                notice: 'Campaign deleted.'
  end

  # POST /organizations/:org_id/attestation_campaigns/:id/launch
  def launch
    users = @organization.users.to_a
    @campaign.launch!(users)
    redirect_to organization_attestation_campaign_path(@organization, @campaign),
                notice: "Campaign launched! #{users.count} users have been notified."
  end

  # PATCH /organizations/:org_id/attestation_campaigns/:id/close
  def close
    @campaign.close!
    redirect_to organization_attestation_campaign_path(@organization, @campaign),
                notice: 'Campaign has been closed.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_campaign
    @campaign = @organization.attestation_campaigns.find(params[:id])
  end

  def campaign_params
    params.require(:attestation_campaign).permit(:title, :description, :policy_id, :deadline, :status)
  end

  def calculate_avg_completion
    active = @organization.attestation_campaigns.status_active
    return 0 if active.empty?

    rates = active.map(&:completion_rate)
    (rates.sum / rates.size).round(1)
  end

  def authorize_campaign
    case action_name
    when 'index'
      authorize AttestationCampaign.new(organization: @organization), :index?
    when 'show', 'launch', 'close'
      authorize @campaign, :show?
    when 'new', 'create'
      authorize AttestationCampaign.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @campaign, :update?
    when 'destroy'
      authorize @campaign, :destroy?
    end
  end
end
