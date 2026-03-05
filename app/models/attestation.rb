class Attestation < ApplicationRecord
  belongs_to :attestation_campaign
  belongs_to :user

  # Enums
  enum status: {
    pending: 0,
    completed: 1,
    declined: 2,
    expired: 3
  }, _prefix: true

  # Validations
  validates :user_id, uniqueness: { scope: :attestation_campaign_id, message: "has already been added to this campaign" }

  # Scopes
  scope :pending_attestations, -> { where(status: :pending) }
  scope :completed_attestations, -> { where(status: :completed) }
  scope :recent, -> { order(attested_at: :desc) }

  def attest!(request)
    update!(
      status: :completed,
      attested_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      policy_version: attestation_campaign.policy.updated_at.to_s
    )
  end

  def attested?
    status_completed?
  end

  # Immutable — prevent updates after attestation
  before_update :prevent_modification_after_attestation

  private

  def prevent_modification_after_attestation
    if attested_at_was.present? && !status_changed?
      errors.add(:base, "Attestation record cannot be modified after completion")
      throw :abort
    end
  end
end
