class Provider < ApplicationRecord
  acts_as_tenant(:organization, optional: true) # Optional for platform-wide providers

  # Associations
  has_many :compliance_frameworks, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :code, presence: true, uniqueness: { scope: :organization_id }, length: { minimum: 2, maximum: 20 }
  validates :jurisdiction, presence: true
  validates :country, presence: true
  validates :website,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: 'must be a valid URL' }, allow_blank: true
  validate :platform_wide_code_uniqueness

  # Enums
  enum status: { active: 0, inactive: 1, deprecated: 2 }
  enum provider_type: { platform_wide: 0, organization_specific: 1 }

  # JSONB Settings
  jsonb_accessor :contact_info,
                 email: :string,
                 phone: :string,
                 address: :text,
                 primary_contact: :string,
                 secondary_contact: :string

  jsonb_accessor :settings,
                 provider_category: :string,
                 regulatory_authority: :boolean,
                 enforcement_powers: :boolean,
                 reporting_requirements: [:string],
                 filing_deadlines: :json,
                 fee_structure: :json,
                 compliance_areas: [:string],
                 custom_fields: :json

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_name, -> { order(:name) }
  scope :by_jurisdiction, ->(jurisdiction) { where(jurisdiction: jurisdiction) }
  scope :by_country, ->(country) { where(country: country) }
  scope :regulatory_authorities, -> { where("settings->>'regulatory_authority' = 'true'") }
  scope :with_enforcement_powers, -> { where("settings->>'enforcement_powers' = 'true'") }
  scope :platform_wide, -> { where(organization_id: nil) }
  scope :organization_specific, -> { where.not(organization_id: nil) }
  scope :available_for_organization, ->(org) { where('organization_id IS NULL OR organization_id = ?', org.id) }

  # Callbacks
  before_validation :generate_code, if: :name_changed?
  before_validation :set_provider_type

  # Instance methods
  def display_name
    "#{name} (#{code})"
  end

  def full_jurisdiction
    [state, country].compact.join(', ')
  end

  def contact_summary
    {
      primary_contact: contact_info[:primary_contact],
      email: contact_info[:email],
      phone: contact_info[:phone]
    }
  end

  def compliance_areas_list
    settings[:compliance_areas] || []
  end

  def reporting_requirements_list
    settings[:reporting_requirements] || []
  end

  def has_enforcement_powers?
    settings[:enforcement_powers] == true
  end

  def is_regulatory_authority?
    settings[:regulatory_authority] == true
  end

  def framework_count
    compliance_frameworks.count
  end

  def active_framework_count
    compliance_frameworks.active.count
  end

  def recent_frameworks(limit = 5)
    compliance_frameworks.order(created_at: :desc).limit(limit)
  end

  def upcoming_enforcement_frameworks
    compliance_frameworks.joins(:compliance_requirements)
                         .where('enforcement_date BETWEEN ? AND ?', Date.current, 90.days.from_now)
                         .distinct
  end

  def platform_wide?
    read_attribute(:organization_id).nil?
  end

  def organization_specific?
    read_attribute(:organization_id).present?
  end

  def can_be_edited_by?(user)
    return true if user.super_admin? && platform_wide?
    return true if user.organization_admin? && read_attribute(:organization_id) == user.organization_id

    false
  end

  def can_be_deleted_by?(user)
    return false if platform_wide? && !user.super_admin?
    return true if user.super_admin?
    return true if user.organization_admin? && read_attribute(:organization_id) == user.organization_id

    false
  end

  private

  def generate_code
    return if code.present?

    # Generate a code from the name
    base_code = name.gsub(/[^A-Za-z0-9]/, '').upcase.first(10)
    counter = 1

    # Check uniqueness within the same scope (platform-wide or organization-specific)
    scope_condition = platform_wide? ? { organization_id: nil } : { organization_id: read_attribute(:organization_id) }

    while Provider.where(scope_condition).exists?(code: base_code)
      base_code = "#{name.gsub(/[^A-Za-z0-9]/, '').upcase.first(8)}#{counter}"
      counter += 1
    end

    self.code = base_code
  end

  def set_provider_type
    self.provider_type = platform_wide? ? :platform_wide : :organization_specific
  end

  def platform_wide_code_uniqueness
    return unless platform_wide?

    return unless Provider.where(organization_id: nil).where.not(id: id).exists?(code: code)

    errors.add(:code, 'must be unique for platform-wide providers')
  end
end
