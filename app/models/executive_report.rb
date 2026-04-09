class ExecutiveReport < ApplicationRecord
  belongs_to :organization
  belongs_to :generated_by, class_name: 'User', optional: true

  enum report_type: { quarterly: 0, annual: 1, ad_hoc: 2 }, _prefix: true
  enum status: { generating: 0, draft: 1, published: 2 }, _prefix: true

  validates :title, presence: true
  validates :report_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :published_reports, -> { where(status: :published) }

  def period_label
    return 'N/A' unless period_start && period_end
    "#{period_start.strftime('%b %Y')} – #{period_end.strftime('%b %Y')}"
  end

  def metric(key)
    metrics&.dig(key.to_s)
  end
end
