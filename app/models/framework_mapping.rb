class FrameworkMapping < ApplicationRecord
  belongs_to :organization
  belongs_to :source_requirement, class_name: 'ComplianceRequirement'
  belongs_to :target_requirement, class_name: 'ComplianceRequirement'

  # Enums
  enum mapping_type: {
    exact: 0,
    partial: 1,
    related: 2
  }, _prefix: true

  # Validations
  validates :mapping_type, presence: true
  validates :source_requirement_id, uniqueness: { scope: :target_requirement_id,
            message: "mapping already exists for this pair" }
  validate :different_frameworks

  # Scopes
  scope :exact_matches, -> { where(mapping_type: :exact) }
  scope :ai_generated, -> { where(ai_generated: true) }
  scope :manual, -> { where(ai_generated: false) }
  scope :high_confidence, -> { where('confidence >= ?', 0.8) }
  scope :by_framework_pair, ->(source_fw_id, target_fw_id) {
    joins("INNER JOIN compliance_requirements src ON src.id = framework_mappings.source_requirement_id")
    .joins("INNER JOIN compliance_requirements tgt ON tgt.id = framework_mappings.target_requirement_id")
    .where("src.compliance_framework_id = ? AND tgt.compliance_framework_id = ?", source_fw_id, target_fw_id)
  }
  scope :for_requirement, ->(req_id) {
    where(source_requirement_id: req_id).or(where(target_requirement_id: req_id))
  }

  def source_framework
    source_requirement&.compliance_framework
  end

  def target_framework
    target_requirement&.compliance_framework
  end

  private

  def different_frameworks
    if source_requirement&.compliance_framework_id == target_requirement&.compliance_framework_id
      errors.add(:base, "Source and target must be from different frameworks")
    end
  end
end
