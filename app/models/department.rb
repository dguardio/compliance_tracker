class Department < ApplicationRecord
  resourcify
  acts_as_tenant(:organization)
  # Associations
  belongs_to :organization
  has_many :teams, dependent: :destroy
  has_many :units, through: :teams
  has_many :users, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: { scope: :organization_id }
  validates :organization, presence: true

  # Enums
  enum status: { active: 0, inactive: 1, archived: 2 }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 description: :string,
                 compliance_focus: [:string],
                 department_type: :string,
                 contact_info: :json,
                 custom_fields: :json

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_name, -> { order(:name) }
  scope :for_organization, ->(org) { where(organization: org) }

  # Instance methods
  def display_name
    "#{name} (#{organization.name})"
  end

  def active?
    status == 'active'
  end

  def user_count
    users.count
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
