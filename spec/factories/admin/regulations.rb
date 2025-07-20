FactoryBot.define do
  factory :admin_regulation, class: 'Admin::Regulation' do
    title { "MyString" }
    agency { "MyString" }
    jurisdiction { "MyString" }
    reg_type { "MyString" }
    version { 1 }
    effective_date { "2025-07-17" }
    status { "MyString" }
    full_text { "" }
    files { "" }
    metadata { "" }
    external_id { "MyString" }
    previous_version_id { 1 }
  end
end
