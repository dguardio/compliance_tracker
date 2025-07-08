class ComplianceRequirement < ApplicationRecord
  acts_as_tenant(:organization)
  resourcify

  # Associations
  belongs_to :compliance_framework
  has_many :compliance_controls, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :code, presence: true, uniqueness: { scope: %i[organization_id compliance_framework_id] }
  validates :requirement_type, presence: true
  validates :priority, presence: true, inclusion: { in: 1..5 }
  validates :status, presence: true
  validates :compliance_framework, presence: true

  # Enums
  enum requirement_type: {
    policy: 0,
    procedure: 1,
    technical_control: 2,
    administrative_control: 3,
    physical_control: 4,
    monitoring: 5,
    reporting: 6
  }

  enum status: {
    pending: 0,
    in_progress: 1,
    implemented: 2,
    verified: 3,
    non_compliant: 4,
    exempt: 5
  }

  # Callbacks
  before_validation :generate_code, if: :name_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 category: :string,
                 risk_level: :string,
                 implementation_notes: :text,
                 verification_method: :string,
                 due_date: :date,
                 responsible_party: :string,
                 dependencies: [:string],
                 custom_fields: :json

  # Scopes
  scope :active, -> { where.not(status: :exempt) }
  scope :by_priority, -> { order(:priority) }
  scope :by_status, -> { order(:status) }
  scope :high_priority, -> { where(priority: [4, 5]) }
  scope :overdue, -> { where("settings->>'due_date' < ?", Date.current.to_s) }
  scope :for_type, ->(type) { where(requirement_type: type) }
  scope :for_status, ->(status) { where(status: status) }

  # Instance methods
  def display_name
    "#{code}: #{name}"
  end

  def overdue?
    return false unless settings[:due_date].present?

    settings[:due_date] < Date.current
  end

  def compliance_status
    return 'exempt' if status == 'exempt'
    return 'non_compliant' if status == 'non_compliant'
    return 'verified' if status == 'verified'
    return 'implemented' if status == 'implemented'
    return 'in_progress' if status == 'in_progress'

    'pending'
  end

  def control_count
    compliance_controls.count
  end

  def effective_controls_count
    compliance_controls.where(status: :effective).count
  end

  def implementation_progress
    return 0 if compliance_controls.empty?

    (effective_controls_count.to_f / control_count * 100).round(2)
  end

  def risk_level_color
    case settings[:risk_level]
    when 'high'
      'red'
    when 'medium'
      'yellow'
    when 'low'
      'green'
    else
      'gray'
    end
  end

  def days_until_due
    return nil unless settings[:due_date].present?

    (settings[:due_date] - Date.current).to_i
  end

  def urgent?
    days_until_due && days_until_due <= 7
  end

  private

  def generate_code
    return if code.present?

    # Generate a code based on framework and requirement count
    framework_code = compliance_framework&.name&.first(3)&.upcase || 'REQ'
    requirement_count = compliance_framework&.compliance_requirements&.count || 0
    self.code = "#{framework_code}-#{format('%03d', requirement_count + 1)}"
  end
end
