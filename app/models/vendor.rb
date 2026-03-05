class Vendor < ApplicationRecord
  belongs_to :organization
  has_many :vendor_assessments, dependent: :destroy

  enum risk_tier: { critical: 0, high: 1, medium: 2, low: 3 }, _prefix: true
  enum status: { active: 0, inactive: 1, under_review: 2, offboarding: 3 }, _prefix: true

  validates :name, presence: true, uniqueness: { scope: :organization_id }

  scope :by_risk, -> { order(:risk_tier) }
  scope :contracts_expiring, ->(days = 30) { where('contract_end BETWEEN ? AND ?', Date.current, days.days.from_now) }

  def latest_assessment
    vendor_assessments.order(assessment_date: :desc).first
  end

  def risk_tier_color
    { 'critical' => 'red', 'high' => 'orange', 'medium' => 'yellow', 'low' => 'green' }[risk_tier]
  end

  def contract_active?
    contract_end.nil? || contract_end >= Date.current
  end
end
