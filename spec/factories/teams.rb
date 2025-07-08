FactoryBot.define do
  factory :team do
    name { "MyString" }
    slug { "MyString" }
    department { nil }
    settings { "" }
    status { 1 }
  end
end
