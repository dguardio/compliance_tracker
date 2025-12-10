# frozen_string_literal: true

class Joyful::StatusPillComponent < ViewComponent::Base
  def initialize(status:, text: nil)
    @status = status.to_s.downcase.gsub(' ', '_').to_sym
    @text = text || status.to_s.humanize
  end

  def call
    tag.span(@text, class: class_names(base_classes, variant_classes))
  end

  private

  def base_classes
    "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize"
  end

  def variant_classes
    case @status
    when :compliant, :active, :completed, :published
      "bg-success-50 text-success-700"
    when :review, :pending, :in_progress, :draft
      "bg-warning-50 text-warning-700"
    when :breach, :non_compliant, :critical, :failed, :archive
      "bg-danger-50 text-danger-700"
    else
      "bg-gray-100 text-gray-800"
    end
  end
end
