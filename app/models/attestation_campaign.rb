class AttestationCampaign < ApplicationRecord
  belongs_to :organization
  belongs_to :policy
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :attestations, dependent: :destroy

  # Enums
  enum status: {
    draft: 0,
    active: 1,
    closed: 2,
    cancelled: 3
  }, _prefix: true

  # Validations
  validates :title, presence: true
  validates :status, presence: true
  validates :deadline, presence: true

  # Scopes
  scope :active_campaigns, -> { where(status: :active) }
  scope :overdue, -> { active_campaigns.where('deadline < ?', Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  def launch!(users)
    transaction do
      update!(status: :active)
      users.each do |user|
        attestations.find_or_create_by!(user: user) do |a|
          a.status = :pending
          a.policy_version = policy.updated_at.to_s
        end
      end
    end
  end

  def completion_rate
    return 0 if attestations.empty?

    completed = attestations.where(status: :completed).count
    (completed.to_f / attestations.count * 100).round(1)
  end

  def pending_count
    attestations.where(status: :pending).count
  end

  def completed_count
    attestations.where(status: :completed).count
  end

  def overdue?
    deadline.present? && deadline < Time.current && status_active?
  end

  def close!
    update!(status: :closed)
  end

  # Auto-escalation: find users who haven't attested past deadline
  def overdue_users
    return [] unless overdue?

    attestations.where(status: :pending).includes(:user).map(&:user)
  end
end
