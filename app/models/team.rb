class Team < ApplicationRecord
  resourcify
  # acts_as_tenant(:organization, through: :department)

  # Associations
  belongs_to :department
  has_many :units, dependent: :destroy
  has_many :users, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: { scope: :department_id }
  validates :department, presence: true

  # Enums
  enum status: { active: 0, inactive: 1, archived: 2 }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 description: :string,
                 team_type: :string,
                 compliance_responsibilities: [:string],
                 contact_info: :json,
                 custom_fields: :json

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_name, -> { order(:name) }
  scope :for_department, ->(dept) { where(department: dept) }
  scope :for_organization, ->(org) { joins(:department).where(departments: { organization: org }) }

  # Instance methods
  def display_name
    "#{name} (#{department.name} - #{department.organization.name})"
  end

  def active?
    status == 'active'
  end

  def user_count
    users.count
  end

  def unit_count
    units.count
  end

  def organization
    department.organization
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
