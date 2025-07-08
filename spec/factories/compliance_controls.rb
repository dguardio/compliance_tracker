FactoryBot.define do
  factory :compliance_control do
    name { "MyString" }
    control_type { 1 }
    description { "MyText" }
    effectiveness { 1 }
    status { 1 }
    compliance_requirement { nil }
    organization { nil }
    settings { "" }
  end
end
