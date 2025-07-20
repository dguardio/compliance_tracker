class Regulation < ApplicationRecord
  # Associations
  has_many :organization_regulations, dependent: :destroy
  has_many :organizations, through: :organization_regulations

  # For future: associations to compliance frameworks, requirements, controls
  # has_many :compliance_framework_regulations
  # has_many :compliance_frameworks, through: :compliance_framework_regulations
  # has_many :compliance_requirements, through: :compliance_framework_regulations
  # has_many :compliance_controls, through: :compliance_framework_regulations

  belongs_to :previous_version, class_name: 'Regulation', optional: true

  # Validations
  validates :title, :agency, :jurisdiction, presence: true
  validates :full_text, presence: true
  validates :version, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :by_agency, ->(agency) { where(agency: agency) }
  scope :by_jurisdiction, ->(jurisdiction) { where(jurisdiction: jurisdiction) }
  scope :by_type, ->(reg_type) { where(reg_type: reg_type) }

  # Callbacks
  after_create :trigger_auto_assignment_to_organizations

  # Helper methods for JSONB fields
  def main_text
    full_text['main']
  end

  def section_text(section)
    full_text.dig('sections', section)
  end

  def file_url(type)
    files[type.to_s]
  end

  def source_url
    metadata['source_url']
  end

  def tags
    metadata['tags'] || []
  end

  def previous
    previous_version
  end

  def amended?
    status == 'amended' || previous_version.present?
  end

  def repealed?
    status == 'repealed'
  end

  def effective?
    status == 'active' && (effective_date.nil? || effective_date <= Date.today)
  end

  def as_json(options = {})
    super.merge({
                  main_text: main_text,
                  files: files,
                  metadata: metadata
                })
  end

  private

  def trigger_auto_assignment_to_organizations
    RegulationAutoAssignmentService.new.assign_regulation_to_organizations(self)
  rescue StandardError => e
    Rails.logger.error "Failed to trigger auto-assignment for regulation #{id}: #{e.message}"
  end
end
