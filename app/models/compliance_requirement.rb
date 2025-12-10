class ComplianceRequirement < ApplicationRecord
  acts_as_tenant(:organization)
  resourcify
  has_paper_trail

  # Associations
  belongs_to :compliance_framework
  has_many :compliance_controls, dependent: :destroy
  has_many :risk_assessments, dependent: :destroy
  has_many :evidence_requests, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 200 }
  validates :code, presence: true, uniqueness: { scope: %i[organization_id compliance_framework_id] }
  validates :requirement_type, presence: true
  validates :priority, presence: true
  validates :status, presence: true
  validates :compliance_framework, presence: true

  # Enums
  enum requirement_type: {
    legal_basis: 0,
    data_subject_rights: 1,
    risk_assessment: 2,
    incident_management: 3,
    governance: 4,
    financial_controls: 5,
    management_assessment: 6,
    audit_oversight: 7,
    whistleblower: 8,
    inventory_management: 9,
    usage_monitoring: 10,
    open_source: 11,
    vendor_management: 12
  }

  enum status: {
    active: 0,
    inactive: 1,
    draft: 2
  }

  enum priority: {
    low: 0,
    medium: 1,
    high: 2
  }

  enum risk_level: {
    risk_low: 0,
    risk_medium: 1,
    risk_high: 2,
    risk_critical: 3
  }

  # Callbacks
  before_validation :generate_code, if: :name_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 category: :string,
                 implementation_notes: :text,
                 verification_method: :string,
                 due_date: :date,
                 responsible_party: :string,
                 dependencies: [:string],
                 custom_fields: :json

  # Scopes
  scope :active, -> { where.not(status: :inactive) }
  scope :by_priority, -> { order(:priority) }
  scope :by_status, -> { order(:status) }
  scope :high_priority, -> { where(priority: :high) }
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
    return 'inactive' if status == 'inactive'
    return 'draft' if status == 'draft'
    return 'active' if status == 'active'

    'unknown'
  end

  def control_count
    compliance_controls.count
  end

  def effective_controls_count
    compliance_controls.where(status: :active).count
  end

  def implementation_progress
    return 0 if compliance_controls.empty?

    (effective_controls_count.to_f / control_count * 100).round(2)
  end

  def risk_level_color
    case risk_level
    when 'risk_critical'
      'red'
    when 'risk_high'
      'orange'
    when 'risk_medium'
      'yellow'
    when 'risk_low'
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
