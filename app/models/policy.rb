class Policy < ApplicationRecord
  acts_as_tenant(:organization)
  has_rich_text :content
  has_one_attached :file
  
  # Associations
  has_many :policy_links, dependent: :destroy
  has_many :attestation_campaigns, dependent: :destroy
  has_many :regulations, through: :policy_links, source: :linkable, source_type: 'Regulation'
  has_many :compliance_controls, through: :policy_links, source: :linkable, source_type: 'ComplianceControl'
  has_many :risk_assessments, through: :policy_links, source: :linkable, source_type: 'RiskAssessment'
  has_many :comments, as: :commentable, dependent: :destroy

  # Enums
  enum status: { draft: 0, active: 1, archived: 2 }

  # Validations
  validates :title, presence: true
  validates :status, presence: true

  # Callbacks
  before_save :extract_content_from_file, if: -> { file.attached? && file.changes.any? }

  private

  def extract_content_from_file
    return if content.present? && !file.changed? # Don't overwrite if content exists and file hasn't changed

    text = case file.content_type
           when 'application/pdf'
             extract_pdf_text
           when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
             extract_docx_text
           end

    self.content = text if text.present?
  end

  def extract_pdf_text
    require 'pdf-reader'
    io = StringIO.new(file.download)
    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n\n")
  rescue StandardError => e
    Rails.logger.error("Failed to extract PDF text: #{e.message}")
    nil
  end

  def extract_docx_text
    require 'docx'
    # Docx gem needs a file path or object, let's try with tempfile
    text = nil
    file.open do |tempfile|
      doc = Docx::Document.open(tempfile.path)
      text = doc.paragraphs.map(&:to_html).join("\n")
    end
    text
  rescue StandardError => e
    Rails.logger.error("Failed to extract DOCX text: #{e.message}")
    nil
  end
end
