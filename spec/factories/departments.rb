FactoryBot.define do
  factory :department do
    name { "MyString" }
    slug { "MyString" }
    organization { nil }
    settings { "" }
    status { 1 }
  end
end
