FactoryBot.define do
  factory :policy do
    title { "MyString" }
    description { "MyText" }
    status { 1 }
    effective_date { "2025-11-27" }
    organization { nil }
  end
end
