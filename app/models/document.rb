class Document < ApplicationRecord
  acts_as_tenant(:organization, optional: true)
  has_paper_trail

  # Associations
  belongs_to :organization, optional: true
  belongs_to :regulation, optional: true
  belongs_to :compliance_framework, optional: true
  belongs_to :compliance_requirement, optional: true
  belongs_to :compliance_control, optional: true
  belongs_to :uploaded_by, class_name: 'User'
  belongs_to :approved_by, class_name: 'User', optional: true

  # Active Storage for file attachments
  has_one_attached :file

  # Validations
  validates :title, presence: true, length: { minimum: 2, maximum: 200 }
  validates :category, presence: true
  validates :status, presence: true
  validates :uploaded_by, presence: true
  validates :organization, presence: true, unless: -> { regulation.present? }
  validates :file, presence: true, on: :create
  validate :file_type_allowed
  validate :file_size_limit
  validate :expires_at_after_created_at, if: :expires_at?

  # Enums
  enum status: {
    draft: 0,
    review: 1,
    approved: 2,
    archived: 3,
    expired: 4
  }

  # JSONB Settings
  jsonb_accessor :settings,
                 tags: [:string],
                 document_type: :string,
                 department: :string,
                 team: :string,
                 unit: :string,
                 review_cycle: :string,
                 approval_workflow: :json,
                 custom_fields: :json,
                 metadata: :json

  # Scopes
  scope :active, -> { where.not(status: %i[archived expired]) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_status, ->(status) { where(status: status) }
  scope :expired, -> { where('expires_at < ?', Date.current) }
  scope :expiring_soon, -> { where('expires_at BETWEEN ? AND ?', Date.current, 30.days.from_now) }
  scope :needs_review, -> { where(status: :review) }
  scope :approved, -> { where(status: :approved) }
  scope :by_uploaded_by, ->(user) { where(uploaded_by: user) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_framework, ->(framework) { where(compliance_framework: framework) }
  scope :by_requirement, ->(requirement) { where(compliance_requirement: requirement) }
  scope :by_control, ->(control) { where(compliance_control: control) }

  # Callbacks
  before_save :update_version, if: :file_attachment_changed?
  before_save :check_expiration
  after_save :send_notifications

  # Instance methods
  def display_name
    "#{title} (v#{version})"
  end

  def file_extension
    return nil unless file.attached?

    file.filename.extension.downcase
  end

  def file_size_mb
    return 0 unless file.attached?

    (file.byte_size / 1024.0 / 1024.0).round(2)
  end

  def file_type
    return nil unless file.attached?

    file.content_type
  end

  def file_attachment_changed?
    # For Active Storage, we can't easily detect changes during seeding
    # So we'll use a simpler approach: check if this is a new record with a file
    new_record? && file.attached?
  end

  def approved?
    status == 'approved'
  end

  def expired?
    expires_at.present? && expires_at < Date.current
  end

  def expiring_soon?
    expires_at.present? && expires_at.between?(Date.current, 30.days.from_now)
  end

  def needs_review?
    status == 'review'
  end

  def can_be_approved_by?(user)
    return false unless user
    return true if user.super_admin?
    return true if user.organization_admin? && user.organization == organization
    return true if user.compliance_officer?

    # Check if user is in approval workflow
    approval_workflow = settings[:approval_workflow] || {}
    approvers = approval_workflow['approvers'] || []
    approvers.include?(user.id.to_s)
  end

  def approve!(user)
    return false unless can_be_approved_by?(user)

    update!(
      status: :approved,
      approved_by: user,
      approved_at: Time.current
    )
  end

  def reject!(user, reason = nil)
    return false unless can_be_approved_by?(user)

    update!(
      status: :draft,
      approved_by: nil,
      approved_at: nil
    )

    # Store rejection reason in settings
    current_settings = settings || {}
    current_settings[:rejection_reason] = reason
    current_settings[:rejected_by] = user.id
    current_settings[:rejected_at] = Time.current
    update!(settings: current_settings)
  end

  def submit_for_review!
    update!(status: :review)
  end

  def archive!
    update!(status: :archived)
  end

  def duplicate!
    new_document = dup
    new_document.title = "#{title} (Copy)"
    new_document.status = :draft
    new_document.version = 1
    new_document.approved_by = nil
    new_document.approved_at = nil
    new_document.uploaded_by = uploaded_by
    new_document.file.attach(file.blob) if file.attached?
    new_document.save!
    new_document
  end

  def days_until_expiry
    return nil unless expires_at

    (expires_at.to_date - Date.current).to_i
  end

  def compliance_hierarchy
    [compliance_framework&.name, compliance_requirement&.name, compliance_control&.name].compact.join(' > ')
  end

  def searchable_content
    [
      title,
      description,
      category,
      tags_array&.join(' '),
      compliance_framework&.name,
      compliance_requirement&.name,
      compliance_control&.name,
      uploaded_by&.full_name
    ].compact.join(' ')
  end

  # Safely handle tags that might be stored as a string or array
  def tags_array
    return [] unless tags.present?

    if tags.is_a?(Array)
      tags
    elsif tags.is_a?(String)
      begin
        JSON.parse(tags)
      rescue JSON::ParserError
        # If it's not valid JSON, try to parse it as a comma-separated string
        tags.split(',').map(&:strip).reject(&:blank?)
      end
    else
      []
    end
  end

  # Preview methods for different file types
  def previewable?
    return false unless file.attached?

    %w[image/jpeg image/png image/gif text/plain text/csv application/pdf application/msword
       application/vnd.openxmlformats-officedocument.wordprocessingml.document application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/vnd.ms-powerpoint application/vnd.openxmlformats-officedocument.presentationml.presentation].include?(file.content_type)
  end

  def image_previewable?
    return false unless file.attached?

    %w[image/jpeg image/png image/gif].include?(file.content_type)
  end

  def text_previewable?
    return false unless file.attached?

    %w[text/plain text/csv].include?(file.content_type)
  end

  def pdf_previewable?
    return false unless file.attached?

    file.content_type == 'application/pdf'
  end

  def word_previewable?
    return false unless file.attached?

    %w[
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].include?(file.content_type)
  end

  def excel_previewable?
    return false unless file.attached?

    %w[
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    ].include?(file.content_type)
  end

  def powerpoint_previewable?
    return false unless file.attached?

    %w[
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.presentationml.presentation
    ].include?(file.content_type)
  end

  def office_document?
    return false unless file.attached?

    %w[
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.presentationml.presentation
    ].include?(file.content_type)
  end

  def document_type_category
    return 'unknown' unless file.attached?

    case file.content_type
    when %r{^image/}
      'image'
    when %r{^text/}
      'text'
    when 'application/pdf'
      'pdf'
    when /word/
      'word'
    when /excel|spreadsheet/
      'excel'
    when /powerpoint|presentation/
      'powerpoint'
    else
      'other'
    end
  end

  def preview_icon_class
    case document_type_category
    when 'image'
      'fas fa-image'
    when 'text'
      'fas fa-file-alt'
    when 'pdf'
      'fas fa-file-pdf'
    when 'word'
      'fas fa-file-word'
    when 'excel'
      'fas fa-file-excel'
    when 'powerpoint'
      'fas fa-file-powerpoint'
    else
      'fas fa-file'
    end
  end

  def preview_icon_color
    case document_type_category
    when 'image'
      'text-green-500'
    when 'text'
      'text-blue-500'
    when 'pdf'
      'text-red-500'
    when 'word'
      'text-blue-600'
    when 'excel'
      'text-green-600'
    when 'powerpoint'
      'text-orange-500'
    else
      'text-gray-500'
    end
  end

  # Enhanced preview methods using DocumentPreviewService
  def preview_service
    @preview_service ||= DocumentPreviewService.new(self)
  end

  def preview_data
    preview_service.preview_data
  end

  def preview_content
    preview_data&.dig(:content)
  end

  def preview_metadata
    preview_data&.dig(:metadata) || {}
  end

  def preview_actions
    preview_data&.dig(:actions) || ['download']
  end

  def preview_type
    preview_data&.dig(:type) || 'unknown'
  end

  # Enhanced content extraction methods
  def extract_text_content
    return '' unless text_previewable?

    preview_content || safe_text_content
  end

  def extract_word_content
    return '' unless document_type_category == 'word'

    preview_content || 'Content extraction not available'
  end

  def extract_excel_content
    return {} unless document_type_category == 'excel'

    preview_content || { error: 'Content extraction not available' }
  end

  def extract_powerpoint_content
    return {} unless document_type_category == 'powerpoint'

    preview_content || { error: 'Content extraction not available' }
  end

  def pdf_page_count
    return 0 unless pdf_previewable?

    preview_metadata[:pages] || 0
  end

  def image_dimensions
    return nil unless image_previewable?

    preview_metadata[:dimensions]
  end

  private

  def update_version
    self.version = (self.version || 0) + 1
  end

  def check_expiration
    return unless expires_at.present? && expires_at < Date.current && status != 'expired'

    self.status = :expired
  end

  def send_notifications
    return unless saved_change_to_status?

    case status
    when 'review'
      send_review_notification
    when 'approved'
      send_approval_notification
    when 'expired'
      send_expiration_notification
    end
  end

  def send_review_notification
    # Notify approvers
    approvers = get_approvers
    approvers.each do |approver|
      DocumentNotificationNotifier.with(
        document: self,
        action: :needs_review,
        actor: uploaded_by
      ).deliver_later(approver)
    end
  end

  def send_approval_notification
    # Notify uploader
    DocumentNotificationNotifier.with(
      document: self,
      action: :approved,
      actor: approved_by
    ).deliver_later(uploaded_by)
  end

  def send_expiration_notification
    # Notify organization admins and uploader
    recipients = [uploaded_by] + organization.users.joins(:roles).where(roles: { name: %w[org_admin super_admin] })
    recipients.uniq.each do |recipient|
      DocumentNotificationNotifier.with(
        document: self,
        action: :expired,
        actor: recipient
      ).deliver_later(recipient)
    end
  end

  def get_approvers
    approvers = []

    # Add organization admins
    approvers += organization.users.joins(:roles).where(roles: { name: %w[org_admin super_admin] })

    # Add compliance officers
    approvers += organization.users.joins(:roles).where(roles: { name: 'compliance_officer' })

    # Add specific approvers from workflow
    approval_workflow = settings[:approval_workflow] || {}
    specific_approvers = approval_workflow['approvers'] || []
    approvers += User.where(id: specific_approvers) if specific_approvers.any?

    approvers.uniq
  end

  def file_type_allowed
    return unless file.attached?

    allowed_types = %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-excel
      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      application/vnd.ms-powerpoint
      application/vnd.openxmlformats-officedocument.presentationml.presentation
      text/plain
      text/csv
      image/jpeg
      image/png
      image/gif
    ]

    return if allowed_types.include?(file.content_type)

    errors.add(:file, 'must be a valid document type (PDF, Word, Excel, PowerPoint, or image)')
  end

  def file_size_limit
    return unless file.attached?

    max_size = 50.megabytes # 50MB limit
    return unless file.byte_size > max_size

    errors.add(:file, "must be less than #{max_size / 1.megabyte}MB")
  end

  def expires_at_after_created_at
    return unless expires_at && created_at

    return unless expires_at <= created_at

    errors.add(:expires_at, 'must be after creation date')
  end

  def safe_text_content
    return '' unless file.attached? || file.byte_size > 5.megabytes

    content = file.download.force_encoding('UTF-8')
    content.length > 1000 ? content[0..1000] + "\n\n... (content truncated)" : content
  rescue StandardError => e
    "Error reading file: #{e.message}"
  end
end
