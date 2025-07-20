FactoryBot.define do
  factory :organization_regulation do
    organization { nil }
    regulation { nil }
    compliance_framework { nil }
    priority { 1 }
    status { "MyString" }
    assigned_at { "2025-07-17 11:35:35" }
    assigned_by { nil }
    notes { "MyText" }
  end
end
