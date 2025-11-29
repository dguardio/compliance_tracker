FactoryBot.define do
  factory :policy_link do
    policy { nil }
    linkable { nil }
    citation { "MyString" }
    notes { "MyText" }
  end
end
