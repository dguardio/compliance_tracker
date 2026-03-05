class TestExecution < ApplicationRecord
  belongs_to :test_plan
  belongs_to :tester, class_name: 'User', optional: true
  belongs_to :reviewer, class_name: 'User', optional: true

  has_many :test_samples, dependent: :destroy

  # Enums
  enum status: {
    not_started: 0,
    in_progress: 1,
    completed: 2,
    reviewed: 3,
    rejected: 4
  }, _prefix: true

  enum result: {
    pending: 0,
    pass: 1,
    fail: 2,
    partial: 3,
    not_applicable: 4
  }, _prefix: true

  # Validations
  validates :status, presence: true

  # Scopes
  scope :awaiting_review, -> { where(status: :completed) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  after_save :auto_schedule_next_test, if: :saved_change_to_status?

  def start!
    update!(status: :in_progress, started_at: Time.current)
  end

  def complete!(result_value, notes = nil)
    update!(
      status: :completed,
      result: result_value,
      completed_at: Time.current,
      notes: notes
    )
  end

  def approve!(reviewer_user, notes = nil)
    update!(
      status: :reviewed,
      reviewer: reviewer_user,
      reviewed_at: Time.current,
      reviewer_notes: notes
    )
  end

  def reject!(reviewer_user, notes = nil)
    update!(
      status: :rejected,
      reviewer: reviewer_user,
      reviewed_at: Time.current,
      reviewer_notes: notes
    )
  end

  def calculate_result_from_samples
    return :pending if test_samples.empty?

    sample_results = test_samples.pluck(:result)
    if sample_results.all? { |r| r == 'pass' }
      :pass
    elsif sample_results.all? { |r| r == 'fail' }
      :fail
    elsif sample_results.any? { |r| r == 'fail' }
      :partial
    else
      :pass
    end
  end

  def sample_pass_rate
    return 0 if test_samples.empty?

    passed = test_samples.where(result: :pass).count
    (passed.to_f / test_samples.count * 100).round(1)
  end

  private

  def auto_schedule_next_test
    return unless status_reviewed?

    test_plan.schedule_next!
  end
end
