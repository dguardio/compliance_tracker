class MaturitySnapshot < ApplicationRecord
  belongs_to :compliance_control
  belongs_to :organization

  # Validations
  validates :maturity_level, presence: true,
            inclusion: { in: 1..5, message: "must be between 1 (Ad-hoc) and 5 (Optimized)" }
  validates :snapshot_date, presence: true
  validates :compliance_control_id, uniqueness: { scope: :snapshot_date,
            message: "already has a snapshot for this date" }

  # Scopes
  scope :recent, -> { order(snapshot_date: :desc) }
  scope :for_control, ->(control) { where(compliance_control: control) }
  scope :for_quarter, ->(date) {
    quarter_start = date.beginning_of_quarter
    quarter_end = date.end_of_quarter
    where(snapshot_date: quarter_start..quarter_end)
  }
  scope :by_quarter, -> {
    select("DATE_TRUNC('quarter', snapshot_date) as quarter, AVG(computed_score) as avg_score, AVG(maturity_level) as avg_level")
      .group("DATE_TRUNC('quarter', snapshot_date)")
      .order("quarter")
  }

  # Human-readable maturity level names
  MATURITY_LEVELS = {
    1 => 'Ad-hoc',
    2 => 'Repeatable',
    3 => 'Defined',
    4 => 'Managed',
    5 => 'Optimized'
  }.freeze

  def maturity_label
    MATURITY_LEVELS[maturity_level] || 'Unknown'
  end

  def score_breakdown
    {
      evidence_freshness: evidence_freshness_score || 0,
      testing: testing_score || 0,
      findings: finding_score || 0,
      documentation: documentation_score || 0
    }
  end
end
