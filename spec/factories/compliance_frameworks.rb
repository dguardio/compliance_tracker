FactoryBot.define do
  factory :compliance_framework do
    name { "MyString" }
    slug { "MyString" }
    description { "MyText" }
    version { "MyString" }
    status { 1 }
    organization { nil }
    settings { "" }
  end
end
