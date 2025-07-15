class ComplianceFramework < ApplicationRecord
  acts_as_tenant(:organization)
  resourcify

  # Associations
  has_many :compliance_requirements, dependent: :destroy
  has_many :compliance_controls, through: :compliance_requirements
  has_many :risk_assessments, dependent: :destroy
  belongs_to :provider, optional: true

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: { scope: :organization_id }
  validates :version, presence: true
  validates :status, presence: true
  validates :provider_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: 'must be a valid URL' },
                           allow_blank: true
  validate :enforcement_date_after_publication_date, if: -> { enforcement_date.present? && publication_date.present? }

  # Enums
  enum status: { draft: 0, active: 1, deprecated: 2, archived: 3 }
  
  attribute :issuance_type, :string
  enum issuance_type: {
    Consent_Order: 'Consent Order',
    Final_Rule: 'Final Rule',
    Form: 'Form',
    Guidance: 'Guidance',
    Proposed_Rulemaking: 'Proposed Rulemaking',
    Report: 'Report',
    Press_Release: 'Press Release',
    Speech: 'Speech',
    Notice: 'Notice',
    Interim_Final_Rule: 'Interim Final Rule',
    Executive_Order: 'Executive Order'
  }

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
  scope :by_provider, ->(provider) { where(provider: provider) }
  scope :by_provider_code, ->(code) { joins(:provider).where(providers: { code: code }) }
  scope :by_issuance_type, ->(issuance_type) { where(issuance_type: issuance_type) }
  scope :recent_publications, -> { where('publication_date >= ?', 30.days.ago).order(publication_date: :desc) }
  scope :upcoming_enforcement, lambda {
    where('enforcement_date BETWEEN ? AND ?', Date.current, 90.days.from_now).order(enforcement_date: :asc)
  }
  scope :by_jurisdiction, ->(jurisdiction) { where("settings->>'jurisdiction' = ?", jurisdiction) }
  scope :by_provider_jurisdiction, lambda { |jurisdiction|
    joins(:provider).where(providers: { jurisdiction: jurisdiction })
  }
  scope :regulatory_authorities, -> { joins(:provider).where("providers.settings->>'regulatory_authority' = 'true'") }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[created_at description id id_value name organization_id settings slug status
       updated_at version]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[compliance_requirements compliance_controls]
  end

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

  def regulatory_info
    {
      provider: provider&.name,
      provider_code: provider&.code,
      provider_jurisdiction: provider&.jurisdiction,
      issuance_type: issuance_type,
      publication_date: publication_date,
      provider_url: provider_url,
      enforcement_date: enforcement_date,
      jurisdiction: settings[:jurisdiction]
    }
  end

  def provider_name
    provider&.name
  end

  def provider_code
    provider&.code
  end

  def provider_contact_info
    provider&.contact_summary
  end

  def provider_website
    provider&.website
  end

  def days_until_enforcement
    return nil unless enforcement_date

    (enforcement_date - Date.current).to_i
  end

  def enforcement_urgent?
    days_until_enforcement && days_until_enforcement <= 30
  end

  def publication_age_days
    return nil unless publication_date

    (Date.current - publication_date).to_i
  end

  def impacted_departments_list
    return [] unless potentially_impacted_departments.present?

    potentially_impacted_departments.split(',').map(&:strip)
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end

  def enforcement_date_after_publication_date
    return unless enforcement_date < publication_date

    errors.add(:enforcement_date, 'must be after publication date')
  end
end
