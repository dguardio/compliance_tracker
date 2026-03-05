class ObligationControl < ApplicationRecord
  belongs_to :obligation
  belongs_to :compliance_control

  validates :compliance_control_id, uniqueness: { scope: :obligation_id }
end
