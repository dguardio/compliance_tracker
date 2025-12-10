class EvidenceRequestDocument < ApplicationRecord
  belongs_to :evidence_request
  belongs_to :document
end
