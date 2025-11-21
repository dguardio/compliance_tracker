FactoryBot.define do
  factory :workflow_transition do
    workflow_step { nil }
    next_step { nil }
    condition { "MyString" }
  end
end
