FactoryBot.define do
  factory :organization do
    name { Faker::Company.name }
    slug { Faker::Internet.domain_word }
    domain { Faker::Internet.domain_name }
    settings { {} }
    status { 1 }
  end
end
