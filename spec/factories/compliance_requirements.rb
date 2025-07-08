FactoryBot.define do
  factory :compliance_requirement do
    name { "MyString" }
    code { "MyString" }
    description { "MyText" }
    requirement_type { 1 }
    priority { 1 }
    status { 1 }
    compliance_framework { nil }
    organization { nil }
    settings { "" }
  end
end
