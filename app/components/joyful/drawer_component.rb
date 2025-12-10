# frozen_string_literal: true

class Joyful::DrawerComponent < ViewComponent::Base
  def initialize(title: nil, id: "drawer")
    @title = title
    @id = id
  end
end
