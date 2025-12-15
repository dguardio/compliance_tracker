class Regulation < ApplicationRecord
  include PgSearch::Model
  has_paper_trail

  # Associations
  has_many :organization_regulations, dependent: :destroy
  has_many :organizations, through: :organization_regulations
  belongs_to :previous_version, class_name: 'Regulation', optional: true
  has_many :regulation_extractions, dependent: :destroy
  has_one :document, dependent: :destroy
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :standard_requirements, dependent: :destroy

  # Validations
  validates :title, :agency, :jurisdiction, presence: true
  validates :full_text, presence: true
  validates :revision, numericality: { greater_than: 0 }

  # Scopes
  scope :active, -> { where(status: 'active') }
  
  has_neighbors :embedding

  scope :by_agency, ->(agency) { where(agency: agency) }
  scope :by_jurisdiction, ->(jurisdiction) { where(jurisdiction: jurisdiction) }
  scope :by_type, ->(reg_type) { where(reg_type: reg_type) }
  scope :for_organization, ->(org) { joins(:organization_regulations).where(organization_regulations: { organization_id: org.id }).where.not(organization_regulations: { status: 'archived' }) }
  scope :available_for_organization, ->(org) { where.not(id: org.regulations.pluck(:id)) }

  # PgSearch Configuration
  pg_search_scope :search_by_all,
                  against: [:title, :agency, :jurisdiction],
                  using: {
                    tsearch: { prefix: true, dictionary: 'english' },
                    trigram: { threshold: 0.2 }
                  }

  # Ransack Configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[title agency jurisdiction status created_at keywords_contains]
  end

  ransacker :keywords_contains,
    formatter: proc { |v| v.to_json },
    validator: proc { |v| v.present? },
    type: :string do |parent|
    Arel.sql("metadata->'keywords' @> ?")
  end


  # Callbacks
  after_create :trigger_auto_assignment_to_organizations

  # Helper methods for JSONB fields
  def main_text
    full_text['main']
  end
  # ... (rest of the methods remain the same)
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
    RegulationAutoAssignmentService.new.process_new_regulation(self)
  rescue StandardError => e
    Rails.logger.error "Failed to trigger auto-assignment for regulation #{id}: #{e.message}"
  end
end
