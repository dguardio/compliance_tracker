class Unit < ApplicationRecord
  resourcify
  # acts_as_tenant(:organization, through: %i[team department])

  # Associations
  belongs_to :team
  has_many :users, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :slug, presence: true, uniqueness: { scope: :team_id }
  validates :team, presence: true

  # Enums
  enum status: { active: 0, inactive: 1, archived: 2 }

  # Callbacks
  before_validation :generate_slug, if: :name_changed?

  # JSONB Settings
  jsonb_accessor :settings,
                 description: :string,
                 unit_type: :string,
                 compliance_focus: [:string],
                 contact_info: :json,
                 custom_fields: :json

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :by_name, -> { order(:name) }
  scope :for_team, ->(team) { where(team: team) }
  scope :for_department, ->(dept) { joins(:team).where(teams: { department: dept }) }
  scope :for_organization, ->(org) { joins(team: :department).where(departments: { organization: org }) }

  # Instance methods
  def display_name
    "#{name} (#{team.name} - #{team.department.name} - #{team.department.organization.name})"
  end

  def active?
    status == 'active'
  end

  def user_count
    users.count
  end

  def department
    team.department
  end

  def organization
    team.organization
  end

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
