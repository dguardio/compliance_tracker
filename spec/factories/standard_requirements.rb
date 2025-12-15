FactoryBot.define do
  factory :standard_requirement do
    name { "MyString" }
    description { "MyText" }
    regulation { nil }
    category { "MyString" }
    external_id { "MyString" }
  end
end
