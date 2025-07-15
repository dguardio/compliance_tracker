FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    resource_type { 'Organization' }
    association :organization
    association :resource, factory: :organization
  end
end
