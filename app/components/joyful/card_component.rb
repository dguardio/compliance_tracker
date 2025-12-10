# frozen_string_literal: true

class Joyful::CardComponent < ViewComponent::Base
  renders_one :actions
  renders_one :footer

  def initialize(title: nil, subtitle: nil, icon: nil, padding: true)
    @title = title
    @subtitle = subtitle
    @icon = icon
    @padding = padding
  end
end
