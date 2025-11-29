class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :assignee, class_name: 'User', optional: true
  belongs_to :commentable, polymorphic: true
  
  enum comment_type: { comment: 'comment', suggestion: 'suggestion', evidence_request: 'evidence_request' }
  enum status: { open: 0, resolved: 1 }
  
  validates :content, presence: true
  validates :suggested_text, presence: true, if: :suggestion?
end
