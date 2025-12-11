# frozen_string_literal: true

class Joyful::CardComponent < ViewComponent::Base
  renders_one :actions
  renders_one :footer

  renders_one :card_header, "CardHeader"

  def initialize(title: nil, subtitle: nil, icon: nil, padding: true, **system_arguments)
    @title = title
    @subtitle = subtitle
    @icon = icon
    @padding = padding
    @system_arguments = system_arguments
  end

  class CardHeader < ViewComponent::Base
    def initialize(title: nil, subtitle: nil, icon: nil, path: nil)
      @title = title
      @subtitle = subtitle
      @icon = icon
      @path = path
    end

    def call
      content_tag(:div, class: "px-6 py-4 border-b border-slate-50 flex items-start justify-between") do
        left_content + right_content
      end
    end

    private

    def left_content
      content_tag(:div, class: "flex items-center gap-3") do
        concat icon_markup if @icon
        concat text_content
      end
    end

    def icon_markup
      content_tag(:div, class: "p-2 bg-primary-50 rounded-lg text-primary-600") do
        content_tag(:i, "", class: "#{@icon} text-lg")
      end
    end

    def text_content
      content_tag(:div) do
        if @title
          if @path
            concat link_to(@title, @path, class: "text-base font-semibold text-gray-900 hover:text-primary-600 transition-colors block")
          else
            concat content_tag(:h3, @title, class: "text-base font-semibold text-gray-900")
          end
        end
        concat content_tag(:p, @subtitle, class: "text-sm text-gray-500 tabular-nums") if @subtitle
      end
    end

    def right_content
      content_tag(:div, content, class: "flex items-center gap-2") if content.present?
    end
  end
end
