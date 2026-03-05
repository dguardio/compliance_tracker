class CorrectiveAction < ApplicationRecord
  belongs_to :finding
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :created_by, class_name: 'User', optional: true

  # Enums
  enum action_type: {
    corrective: 0,
    preventive: 1,
    detective: 2
  }, _prefix: true

  enum priority: {
    low: 0,
    medium: 1,
    high: 2,
    critical: 3
  }, _prefix: true

  enum status: {
    planned: 0,
    in_progress: 1,
    completed: 2,
    verified: 3,
    cancelled: 4
  }, _prefix: true

  # Validations
  validates :title, presence: true
  validates :action_type, presence: true
  validates :priority, presence: true
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: [:planned, :in_progress]) }
  scope :overdue, -> { active.where('due_date < ?', Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_save :check_finding_resolution

  def complete!(notes = nil)
    update!(
      status: :completed,
      completed_at: Time.current,
      completion_notes: notes
    )
  end

  def overdue?
    due_date.present? && due_date < Time.current && active?
  end

  def active?
    status_planned? || status_in_progress?
  end

  private

  def check_finding_resolution
    return unless status_completed? || status_verified?

    # Auto-close finding if all corrective actions are complete
    if finding.corrective_actions.active.empty?
      finding.resolve!("All corrective actions completed")
    end
  end
end
