FactoryBot.define do
  factory :regulation do
    title { "Sample Regulation " + Faker::Alphanumeric.alpha(number: 5) }
    jurisdiction { "EU" }
    full_text { { "main" => "Compliance shall be maintained at all times." } }
    metadata { { "source_url" => "http://example.com/reg/" + Faker::Alphanumeric.alpha(number: 5) } }
    
    # Optional fields
    agency { "Regulatory Body" }
    effective_date { Date.today }
  end
end
