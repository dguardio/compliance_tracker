class Organization < ApplicationRecord
  resourcify
  # Associations
  has_many :departments, dependent: :destroy
  has_many :teams, through: :departments
  has_many :units, through: :teams
  has_many :users, dependent: :nullify
  has_many :permissions, dependent: :destroy

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :domain, uniqueness: true, allow_blank: true

  # Enums
  enum status: { active: 0, inactive: 1, suspended: 2 }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 industry: :string,
                 jurisdiction: :string,
                 compliance_keywords: [:string],
                 exclusion_terms: [:string],
                 notification_preferences: :json,
                 ai_settings: :json,
                 branding: :json

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_name, -> { order(:name) }

  # Instance methods
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

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
