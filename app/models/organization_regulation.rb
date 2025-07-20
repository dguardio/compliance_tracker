class OrganizationRegulation < ApplicationRecord
  # Associations
  belongs_to :organization
  belongs_to :regulation
  belongs_to :compliance_framework, optional: true
  belongs_to :assigned_by, class_name: 'User', optional: true

  # Validations
  validates :organization_id, presence: true
  validates :regulation_id, presence: true
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :status, presence: true, inclusion: { in: %w[pending active inactive archived] }

  # Ensure unique organization-regulation pairs
  validates :regulation_id,
            uniqueness: { scope: :organization_id, message: 'is already associated with this organization' }

  # Enums
  enum status: {
    pending: 'pending',
    active: 'active',
    inactive: 'inactive',
    archived: 'archived'
  }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :pending, -> { where(status: 'pending') }
  scope :inactive, -> { where(status: 'inactive') }
  scope :archived, -> { where(status: 'archived') }
  scope :by_priority, -> { order(priority: :desc, created_at: :desc) }
  scope :recently_assigned, -> { order(assigned_at: :desc) }
  scope :with_framework, -> { where.not(compliance_framework_id: nil) }
  scope :without_framework, -> { where(compliance_framework_id: nil) }

  # Callbacks
  before_create :set_assigned_at, if: -> { assigned_at.nil? }

  # Instance methods
  def display_name
    "#{organization.name} - #{regulation.title}"
  end

  def priority_label
    case priority
    when 0..2 then 'Low'
    when 3..5 then 'Medium'
    when 6..8 then 'High'
    when 9..10 then 'Critical'
    else 'Not Set'
    end
  end

  def can_activate?
    %w[pending inactive].include?(status)
  end

  def can_deactivate?
    status == 'active'
  end

  def can_archive?
    status != 'archived'
  end

  def activate!(user = nil)
    return false unless can_activate?

    update!(
      status: 'active',
      assigned_by: user,
      assigned_at: Time.current
    )
  end

  def deactivate!(user = nil)
    return false unless can_deactivate?

    update!(
      status: 'inactive',
      assigned_by: user,
      assigned_at: Time.current
    )
  end

  def archive!(user = nil)
    return false unless can_archive?

    update!(
      status: 'archived',
      assigned_by: user,
      assigned_at: Time.current
    )
  end

  private

  def set_assigned_at
    self.assigned_at = Time.current
  end
end
