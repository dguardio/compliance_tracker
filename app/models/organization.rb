class Organization < ApplicationRecord
  include Flipper::Identifier
  resourcify
  # Associations
  has_many :departments, dependent: :destroy
  has_many :teams, through: :departments
  has_many :units, through: :teams
  has_many :users, dependent: :nullify
  has_many :permissions, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :compliance_frameworks, dependent: :destroy
  has_many :compliance_requirements, through: :compliance_frameworks
  has_many :compliance_controls, through: :compliance_requirements
  has_many :risk_assessments, dependent: :destroy
  has_many :documents, dependent: :destroy
  has_many :providers, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :organization_regulations, dependent: :destroy
  has_many :regulations, through: :organization_regulations
  has_many :workflow_templates, dependent: :destroy
  has_many :evidence_requests, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :domain, uniqueness: true, allow_blank: true

  # Enums
  enum status: { active: 0, inactive: 1, suspended: 2 }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?
  after_update :trigger_regulation_auto_assignment, if: :compliance_profile_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 # Basic Organization Info
                 industry: :string,
                 jurisdiction: :string,
                 size: :string,
                 description: :text,
                 website: :string,
                 contact_email: :string,
                 contact_phone: :string,
                 state: :string,
                 country: :string,

                 # Branding & Visual Identity
                 brand_colors: :json,
                 logo_url: :string,
                 favicon_url: :string,
                 primary_color: :string,
                 secondary_color: :string,
                 accent_color: :string,
                 text_color: :string,
                 background_color: :string,

                 # Regional & Localization
                 timezone: :string,
                 locale: :string,
                 currency: :string,
                 date_format: :string,
                 time_format: :string,

                 # Privacy & Security
                 privacy_level: :string,
                 data_retention_days: :integer,
                 allow_external_sharing: :boolean,
                 require_2fa: :boolean,
                 session_timeout_minutes: :integer,

                 # Compliance & Workflow
                 compliance_keywords: [:string],
                 exclusion_terms: [:string],
                 default_compliance_framework: :string,
                 auto_approval_enabled: :boolean,
                 document_expiry_warning_days: :integer,

                 # Compliance Profile & Auto-Assignment
                 compliance_jurisdictions: [:string],
                 compliance_industries: [:string],
                 compliance_sectors: [:string],
                 compliance_company_size: :string,
                 compliance_data_types: [:string],
                 compliance_geographic_scope: [:string],
                 compliance_risk_level: :string,
                 auto_assignment_enabled: :boolean,
                 assignment_priority_threshold: :integer,

                 # Notifications & Communication
                 notification_preferences: :json,
                 email_signature: :text,
                 welcome_message: :text,

                 # AI & Automation
                 ai_settings: :json,
                 auto_tagging_enabled: :boolean,
                 smart_search_enabled: :boolean,

                 # UI/UX Preferences
                 dashboard_layout: :json,
                 default_view: :string,
                 show_analytics: :boolean,
                 show_recommendations: :boolean,

                 # Integration Settings
                 integrations: :json,
                 api_enabled: :boolean,
                 webhook_urls: [:string],

                 # Custom Fields
                 custom_fields: :json,
                 metadata: :json

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_name, -> { order(:name) }

  # Robust Accessors for JSONB Arrays
  # These handle cases where data might be stored as stringified JSON instead of real arrays
  def compliance_keywords
    safe_parse_json_array(super)
  end

  def exclusion_terms
    safe_parse_json_array(super)
  end

  def compliance_industries
    safe_parse_json_array(super)
  end

  def compliance_jurisdictions
    safe_parse_json_array(super)
  end

  private

  def safe_parse_json_array(value)
    return value if value.is_a?(Array)
    return JSON.parse(value) rescue [] if value.is_a?(String)
    []
  end

  public

  # Instance methods
  # Default values for branding
  def primary_color
    super.presence || '#3B82F6'
  end

  def secondary_color
    super.presence || '#6B7280'
  end

  def accent_color
    super.presence || '#10B981'
  end

  def text_color
    super.presence || '#1F2937'
  end

  def background_color
    super.presence || '#FFFFFF'
  end

  def display_name
    name
  end

  def active?
    status == 'active'
  end

  def user_count
    users.count
  end

  def department_count
    departments.count
  end

  def team_count
    teams.count
  end

  def unit_count
    units.count
  end

  def compliance_framework_count
    compliance_frameworks.count
  end

  def compliance_requirement_count
    compliance_requirements.count
  end

  def compliance_control_count
    compliance_controls.count
  end

  def risk_assessment_count
    risk_assessments.count
  end

  def role_count
    roles.count
  end

  def permission_count
    permissions.count
  end

  def document_count
    documents.count
  end

  def provider_count
    providers.count
  end

  def regulation_count
    regulations.count
  end

  def active_regulation_count
    organization_regulations.active.count
  end

  def pending_regulation_count
    organization_regulations.pending.count
  end

  def high_priority_regulations
    organization_regulations.where('priority >= ?', 6).by_priority
  end

  def regulations_by_framework(framework)
    organization_regulations.where(compliance_framework: framework)
  end

  def regulations_without_framework
    organization_regulations.without_framework
  end
  
  def applicable_regulations
    regulations.where(organization_regulations: { status: ['active', 'pending'] })
  end
  
  def add_regulation(regulation, assigned_by:, notes: nil, priority: 0)
    organization_regulations.create!(
      regulation: regulation,
      assigned_by_id: assigned_by.id,
      assigned_at: Time.current,
      notes: notes,
      priority: priority,
      status: 'pending'
    )
  end

  def available_providers
    Provider.available_for_organization(self)
  end

  def platform_wide_providers
    Provider.platform_wide
  end

  def organization_specific_providers
    providers
  end

  def get_provider_recommendations
    ProviderRecommendationService.new(self).recommended_providers
  end

  def auto_assign_providers
    ProviderRecommendationService.new(self).auto_assign_providers
  end

  # Settings helper methods
  def default_brand_colors
    {
      primary: '#3B82F6',
      secondary: '#6B7280',
      accent: '#10B981',
      text: '#1F2937',
      background: '#FFFFFF',
      success: '#10B981',
      warning: '#F59E0B',
      error: '#EF4444',
      info: '#3B82F6'
    }
  end

  def timezone
    settings['timezone'] || 'UTC'
  end

  def locale
    settings['locale'] || 'en'
  end

  def currency
    settings['currency'] || 'USD'
  end

  def date_format
    settings['date_format'] || 'MM/DD/YYYY'
  end

  def time_format
    settings['time_format'] || '12h'
  end

  def privacy_level
    settings['privacy_level'] || 'standard'
  end

  def data_retention_days
    settings['data_retention_days'] || 2555 # 7 years default
  end

  def allow_external_sharing
    settings['allow_external_sharing'] || false
  end

  def require_2fa
    settings['require_2fa'] || false
  end

  def session_timeout_minutes
    settings['session_timeout_minutes'] || 480 # 8 hours default
  end

  def auto_approval_enabled
    settings['auto_approval_enabled'] || false
  end

  def document_expiry_warning_days
    settings['document_expiry_warning_days'] || 30
  end

  def auto_tagging_enabled
    settings['auto_tagging_enabled'] || true
  end

  def smart_search_enabled
    settings['smart_search_enabled'] || true
  end

  def show_analytics
    settings['show_analytics'] || true
  end

  def show_recommendations
    settings['show_recommendations'] || true
  end

  def api_enabled
    settings['api_enabled'] || false
  end

  def notification_preferences
    settings['notification_preferences'] || default_notification_preferences
  end

  def default_notification_preferences
    {
      email: {
        document_approval: true,
        compliance_deadlines: true,
        risk_alerts: true,
        system_updates: false
      },
      in_app: {
        document_approval: true,
        compliance_deadlines: true,
        risk_alerts: true,
        system_updates: true
      },
      frequency: 'immediate'
    }
  end

  def ai_settings
    settings['ai_settings'] || default_ai_settings
  end

  def default_ai_settings
    {
      content_analysis: true,
      risk_assessment: true,
      compliance_mapping: true,
      document_summarization: true,
      auto_tagging: true
    }
  end

  def dashboard_layout
    settings['dashboard_layout'] || default_dashboard_layout
  end

  def default_dashboard_layout
    {
      widgets: [
        { type: 'compliance_overview', position: 'top-left', size: 'medium' },
        { type: 'recent_documents', position: 'top-right', size: 'medium' },
        { type: 'upcoming_deadlines', position: 'bottom-left', size: 'large' },
        { type: 'risk_summary', position: 'bottom-right', size: 'small' }
      ],
      theme: 'light'
    }
  end

  def integrations
    settings['integrations'] || {}
  end

  def custom_fields
    settings['custom_fields'] || {}
  end

  def metadata
    settings['metadata'] || {}
  end

  # Branding methods
  def has_custom_branding?
    logo_url.present? || primary_color != '#3B82F6'
  end

  def css_variables
    {
      '--primary-color': primary_color,
      '--secondary-color': secondary_color,
      '--accent-color': accent_color,
      '--text-color': text_color || '#1F2937',
      '--background-color': background_color || '#FFFFFF'
    }
  end

  # Privacy and security methods
  def high_privacy_mode?
    privacy_level == 'high'
  end

  def data_retention_policy
    {
      retention_days: data_retention_days,
      auto_delete: data_retention_days > 0,
      archive_after_days: data_retention_days / 2
    }
  end

  # Compliance methods
  def compliance_settings
    {
      auto_approval: auto_approval_enabled,
      expiry_warning_days: document_expiry_warning_days,
      default_framework: default_compliance_framework,
      keywords: compliance_keywords || [],
      exclusions: exclusion_terms || []
    }
  end

  # Compliance Profile helper methods
  def compliance_jurisdictions
    settings['compliance_jurisdictions'] || []
  end

  def compliance_industries
    settings['compliance_industries'] || []
  end

  def compliance_sectors
    settings['compliance_sectors'] || []
  end

  def compliance_company_size
    settings['compliance_company_size'] || 'medium'
  end

  def compliance_data_types
    settings['compliance_data_types'] || []
  end

  def compliance_geographic_scope
    settings['compliance_geographic_scope'] || ['domestic']
  end

  def compliance_risk_level
    settings['compliance_risk_level'] || 'medium'
  end

  def auto_assignment_enabled
    settings['auto_assignment_enabled'] || true
  end

  def assignment_priority_threshold
    settings['assignment_priority_threshold'] || 5
  end

  def compliance_profile
    {
      jurisdictions: compliance_jurisdictions,
      industries: compliance_industries,
      sectors: compliance_sectors,
      company_size: compliance_company_size,
      data_types: compliance_data_types,
      geographic_scope: compliance_geographic_scope,
      risk_level: compliance_risk_level,
      keywords: compliance_keywords,
      exclusion_terms: exclusion_terms
    }
  end

  def has_compliance_profile?
    compliance_jurisdictions.any? || compliance_industries.any? || compliance_sectors.any?
  end

  def compliance_profile_changed?
    return false unless saved_change_to_settings?

    # For now, let's simplify this and just return true if settings changed
    # since the exact comparison is complex with JSONB fields
    true
  end

  private

  def trigger_regulation_auto_assignment
    return unless auto_assignment_enabled?

    UpdateOrganizationAssignmentsJob.perform_later(id)
  rescue StandardError => e
    Rails.logger.error "Failed to enqueue UpdateOrganizationAssignmentsJob for Organization ID #{id}: #{e.message}"
  end

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
