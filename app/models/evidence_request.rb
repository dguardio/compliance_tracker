class EvidenceRequest < ApplicationRecord
  belongs_to :organization
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :compliance_requirement, optional: true
  belongs_to :compliance_control, optional: true
  
  has_many_attached :files
  has_many :evidence_request_documents, dependent: :destroy
  has_many :documents, through: :evidence_request_documents
  has_many :comments, as: :commentable, dependent: :destroy

  enum status: { open: 0, in_progress: 1, submitted: 2, approved: 3, rejected: 4 }

  validates :title, presence: true
  validates :status, presence: true
  
  scope :open_requests, -> { where(status: [:open, :in_progress]) }
  scope :overdue, -> { where('due_date < ?', Date.today).where.not(status: [:approved, :rejected]) }
end
