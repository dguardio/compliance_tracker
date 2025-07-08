FactoryBot.define do
  factory :permission do
    name { "MyString" }
    resource_type { "MyString" }
    resource_id { 1 }
    action { "MyString" }
    conditions { "" }
  end
end
