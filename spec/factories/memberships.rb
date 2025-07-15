FactoryBot.define do
  factory :membership do
    user { nil }
    organization { nil }
    role { "MyString" }
    status { "MyString" }
  end
end
