class EvidenceFreshnessController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_feature!(:evidence_freshness) }
  before_action :set_organization

  def index
    @expired_documents = @organization.documents
                                       .where('expires_at < ?', Date.current)
                                       .where.not(status: :expired)
                                       .includes(:uploaded_by, :compliance_framework, :compliance_control)
                                       .order(expires_at: :asc)

    @expiring_soon = @organization.documents
                                   .where('expires_at BETWEEN ? AND ?', Date.current, 30.days.from_now)
                                   .includes(:uploaded_by, :compliance_framework, :compliance_control)
                                   .order(expires_at: :asc)

    @recently_refreshed = @organization.documents
                                        .where('updated_at > ?', 30.days.ago)
                                        .where.not(expires_at: nil)
                                        .includes(:uploaded_by)
                                        .order(updated_at: :desc)
                                        .limit(10)

    @open_refresh_requests = EvidenceRefreshRequest.joins(:document)
                                                    .where(documents: { organization_id: @organization.id })
                                                    .pending
                                                    .includes(document: [:uploaded_by, :compliance_control])
                                                    .order(created_at: :desc)

    @stats = {
      total_with_expiry: @organization.documents.where.not(expires_at: nil).count,
      expired: @expired_documents.count,
      expiring_soon: @expiring_soon.count,
      healthy: @organization.documents.where('expires_at > ?', 30.days.from_now).count,
      open_requests: @open_refresh_requests.count
    }
  end

  def request_refresh
    document = @organization.documents.find(params[:document_id])

    refresh_request = document.evidence_refresh_requests.create!(
      requester: current_user,
      reason: params[:reason] || "Evidence approaching expiration",
      status: :pending
    )

    # TODO: Send notification to document uploader

    redirect_back fallback_location: evidence_freshness_index_path,
                  notice: "Refresh request sent for '#{document.title}'."
  end

  private

  def set_organization
    @organization = current_user.organization
  end
end
