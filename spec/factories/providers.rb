FactoryBot.define do
  factory :provider do
    name { "MyString" }
    code { "MyString" }
    description { "MyText" }
    website { "MyString" }
    jurisdiction { "MyString" }
    state { "MyString" }
    country { "MyString" }
    contact_info { "" }
    settings { "" }
    status { 1 }
  end
end
