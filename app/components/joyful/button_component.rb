# frozen_string_literal: true

class Joyful::ButtonComponent < ViewComponent::Base
  def initialize(text: nil, variant: :primary, icon: nil, path: nil, method: :get, form: nil, **system_arguments)
    @text = text
    @variant = variant
    @icon = icon
    @path = path
    @method = method
    @form = form
    @system_arguments = system_arguments
  end

  def call
    classes = base_classes + variant_classes
    @system_arguments[:class] = class_names(classes, @system_arguments[:class])

    if @path
      link_to @path, @system_arguments.merge(method: @method) do
        content
      end
    elsif @form
      @form.button @system_arguments do
        content
      end
    else
      button_tag @system_arguments do
        content
      end
    end
  end

  private

  def content
    capture do
      concat tag.i(class: @icon) if @icon.present?
      concat tag.span(@text) if @text.present?
      concat content_tag(:span, &block) if block_given?
    end
  end

  def base_classes
    "inline-flex items-center justify-center gap-2 px-4 py-2 rounded-pill font-medium transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 tabular-nums cursor-pointer"
  end

  def variant_classes
    case @variant.to_sym
    when :primary
      "bg-primary-600 text-white shadow-primary-glow hover:-translate-y-0.5 hover:shadow-lg active:translate-y-0 active:scale-95 focus:ring-primary-500"
    when :secondary
      "bg-white text-gray-700 border border-gray-300 shadow-sm hover:bg-gray-50 hover:-translate-y-0.5 active:translate-y-0 active:scale-95 focus:ring-primary-500"
    when :ghost
      "bg-transparent text-primary-600 hover:bg-primary-50 hover:text-primary-700 active:bg-primary-100"
    when :danger
      "bg-danger-500 text-white shadow-sm hover:bg-danger-600 hover:-translate-y-0.5 active:translate-y-0 active:scale-95 focus:ring-danger-500"
    else
      "bg-primary-600 text-white hover:bg-primary-700"
    end
  end
end
