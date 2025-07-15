FactoryBot.define do
  factory :document do
    title { "MyString" }
    description { "MyText" }
    category { "MyString" }
    status { 1 }
    organization { nil }
    compliance_framework { nil }
    compliance_requirement { nil }
    compliance_control { nil }
    uploaded_by { nil }
    approved_by { nil }
    approved_at { "2025-07-13 14:58:20" }
    expires_at { "2025-07-13 14:58:20" }
    version { 1 }
    settings { "" }
  end
end
