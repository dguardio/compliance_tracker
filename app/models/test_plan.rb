class TestPlan < ApplicationRecord
  belongs_to :organization
  belongs_to :compliance_control
  belongs_to :created_by, class_name: 'User', optional: true

  has_many :test_executions, dependent: :destroy

  # Enums
  enum frequency: {
    quarterly: 0,
    semi_annual: 1,
    annual: 2,
    monthly: 3,
    ad_hoc: 4
  }, _prefix: true

  enum status: {
    draft: 0,
    active: 1,
    paused: 2,
    retired: 3
  }, _prefix: true

  # Validations
  validates :title, presence: true
  validates :frequency, presence: true
  validates :status, presence: true

  # Scopes
  scope :active_plans, -> { where(status: :active) }
  scope :due_soon, -> { active_plans.where('next_due_date <= ?', 14.days.from_now) }
  scope :overdue, -> { active_plans.where('next_due_date < ?', Date.current) }
  scope :recent, -> { order(created_at: :desc) }

  def overdue?
    next_due_date.present? && next_due_date < Date.current && status_active?
  end

  def due_soon?
    next_due_date.present? && next_due_date <= 14.days.from_now.to_date && !overdue?
  end

  def latest_execution
    test_executions.order(created_at: :desc).first
  end

  def pass_rate
    completed = test_executions.where(status: :completed)
    return 0 if completed.empty?

    passed = completed.where(result: :pass).count
    (passed.to_f / completed.count * 100).round(1)
  end

  def schedule_next!(from_date = Date.current)
    interval = case frequency
               when 'monthly' then 1.month
               when 'quarterly' then 3.months
               when 'semi_annual' then 6.months
               when 'annual' then 1.year
               else return # ad_hoc doesn't auto-schedule
               end

    update!(
      next_due_date: from_date + interval,
      last_tested_at: Time.current
    )
  end
end
