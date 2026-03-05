class AttestationsController < ApplicationController
  before_action -> { require_feature!(:policy_attestation) }
  before_action :set_attestation

  # GET /attestations/:id — User-facing attestation page
  def show
    @campaign = @attestation.attestation_campaign
    @policy = @campaign.policy
  end

  # PATCH /attestations/:id/attest — User acknowledges the policy
  def attest
    if @attestation.status_pending?
      @attestation.attest!(request)
      redirect_to root_path, notice: 'Thank you! Your attestation has been recorded.'
    else
      redirect_to root_path, alert: 'This attestation has already been completed.'
    end
  end

  private

  def set_attestation
    @attestation = current_user.attestations.find(params[:id])
  end
end
