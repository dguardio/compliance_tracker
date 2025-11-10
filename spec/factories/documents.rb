FactoryBot.define do
  factory :document do
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    category { Faker::Lorem.word }
    status { 1 }
    association :organization
    association :uploaded_by, factory: :user
    approved_by { nil }
    approved_at { "2025-07-13 14:58:20" }
    expires_at { "2025-07-13 14:58:20" }
    version { 1 }
    settings { {} }
  end
end
