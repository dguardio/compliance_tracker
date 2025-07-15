FactoryBot.define do
  factory :risk_assessment do
    organization { nil }
    compliance_framework { nil }
    compliance_requirement { nil }
    compliance_control { nil }
    name { "MyString" }
    description { "MyText" }
    likelihood { 1 }
    impact { 1 }
    risk_score { 1 }
    status { 1 }
    assessment_date { "2025-07-12" }
    next_review_date { "2025-07-12" }
    mitigation_plan { "MyText" }
    created_by { nil }
    assigned_to { nil }
  end
end
