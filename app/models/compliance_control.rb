class ComplianceControl < ApplicationRecord
  acts_as_tenant(:organization)
  resourcify

  # Associations
  belongs_to :compliance_requirement
  has_many :control_evidences, dependent: :destroy
  has_many :control_tests, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :control_type, presence: true
  validates :effectiveness, presence: true, inclusion: { in: 1..5 }
  validates :status, presence: true
  validates :compliance_requirement, presence: true

  # Enums
  enum control_type: {
    preventive: 0,
    detective: 1,
    corrective: 2,
    deterrent: 3,
    compensating: 4
  }

  enum status: {
    planned: 0,
    implemented: 1,
    effective: 2,
    ineffective: 3,
    retired: 4
  }

  # JSONB Settings
  jsonb_accessor :settings,
                 control_category: :string,
                 implementation_date: :date,
                 last_review_date: :date,
                 next_review_date: :date,
                 responsible_party: :string,
                 cost: :decimal,
                 frequency: :string,
                 automation_level: :string,
                 dependencies: [:string],
                 notes: :text,
                 custom_fields: :json

  # Scopes
  scope :active, -> { where.not(status: :retired) }
  scope :effective, -> { where(status: :effective) }
  scope :by_type, -> { order(:control_type) }
  scope :by_effectiveness, -> { order(:effectiveness) }
  scope :high_effectiveness, -> { where(effectiveness: [4, 5]) }
  scope :needs_review, -> { where("settings->>'next_review_date' < ?", Date.current.to_s) }
  scope :for_category, ->(category) { where("settings->>'control_category' = ?", category) }

  # Instance methods
  def display_name
    "#{name} (#{control_type.titleize})"
  end

  def effective?
    status == 'effective'
  end

  def needs_review?
    return false unless settings[:next_review_date].present?

    settings[:next_review_date] < Date.current
  end

  def effectiveness_percentage
    (effectiveness.to_f / 5 * 100).round(2)
  end

  def effectiveness_color
    case effectiveness
    when 5
      'green'
    when 4
      'light-green'
    when 3
      'yellow'
    when 2
      'orange'
    when 1
      'red'
    else
      'gray'
    end
  end

  def days_until_review
    return nil unless settings[:next_review_date].present?

    (settings[:next_review_date] - Date.current).to_i
  end

  def overdue_for_review?
    days_until_review && days_until_review < 0
  end

  def implementation_age
    return nil unless settings[:implementation_date].present?

    (Date.current - settings[:implementation_date]).to_i
  end

  def cost_formatted
    return 'Not specified' unless settings[:cost].present?

    ActionController::Base.helpers.number_to_currency(settings[:cost])
  end

  def automation_level_percentage
    case settings[:automation_level]
    when 'fully_automated'
      100
    when 'semi_automated'
      75
    when 'manual_automated'
      50
    when 'mostly_manual'
      25
    when 'fully_manual'
      0
    else
      0
    end
  end

  def evidence_count
    control_evidences.count
  end

  def test_count
    control_tests.count
  end

  def last_test_result
    control_tests.order(:created_at).last&.result
  end

  def compliance_framework
    compliance_requirement.compliance_framework
  end
end
