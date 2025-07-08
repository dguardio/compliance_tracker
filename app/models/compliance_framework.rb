class ComplianceFramework < ApplicationRecord
  acts_as_tenant(:organization)
  resourcify

  # Associations
  has_many :compliance_requirements, dependent: :destroy
  has_many :compliance_controls, through: :compliance_requirements

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: { scope: :organization_id }
  validates :version, presence: true
  validates :status, presence: true

  # Enums
  enum status: { draft: 0, active: 1, deprecated: 2, archived: 3 }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 framework_type: :string,
                 jurisdiction: :string,
                 industry_scope: [:string],
                 effective_date: :date,
                 review_frequency: :string,
                 contact_info: :json,
                 custom_fields: :json

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_name, -> { order(:name) }
  scope :by_version, -> { order(:version) }
  scope :for_industry, ->(industry) { where("settings->>'industry_scope' ? :industry", industry: industry) }

  # Instance methods
  def display_name
    "#{name} v#{version}"
  end

  def active?
    status == 'active'
  end

  def requirement_count
    compliance_requirements.count
  end

  def control_count
    compliance_controls.count
  end

  def compliance_score
    return 0 if compliance_requirements.empty?

    total_requirements = compliance_requirements.count
    compliant_requirements = compliance_requirements.joins(:compliance_controls)
                                                   .where(compliance_controls: { status: :effective })
                                                   .distinct.count

    (compliant_requirements.to_f / total_requirements * 100).round(2)
  end

  def next_review_date
    return nil unless settings[:review_frequency].present?

    case settings[:review_frequency]
    when 'monthly'
      effective_date&.next_month
    when 'quarterly'
      effective_date&.next_month(3)
    when 'semi_annually'
      effective_date&.next_month(6)
    when 'annually'
      effective_date&.next_year
    else
      nil
    end
  end

  def overdue_for_review?
    return false unless next_review_date
    next_review_date < Date.current
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
