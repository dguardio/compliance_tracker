# test_ai_services.rb
# Run with: rails runner test_ai_services.rb

Rails.logger.level = Logger::INFO

def run_test(name)
  puts "\n============================================="
  puts "🚀 TESTING: #{name}"
  puts "============================================="
  begin
    yield
    puts "✅ PASS: #{name}"
  rescue => e
    puts "❌ FAIL: #{name}\n   Error: #{e.message}"
    puts e.backtrace.first(3).join("\n   ")
  end
end

# -------------------------------------------------------------
# Setup basic test data
# -------------------------------------------------------------
puts "Setting up test data..."
org = Organization.first_or_create!(name: "Acme Corp Testing", industry: "Technology", website: "acme.example.com")
reg = Regulation.first_or_create!(title: "GDPR Test Dummy", agency: "EU", jurisdiction: "Europe", description: "Privacy stuff")
policy = Policy.first_or_create!(title: "Privacy Policy", description: "We protect data.", organization: org)
user = User.first || User.create!(email: "admin_test_#{SecureRandom.hex}@example.com", password: "password", first_name: "Test", last_name: "Admin", organization: org)

# -------------------------------------------------------------
# Test Ai::Client directly
# -------------------------------------------------------------
run_test("Ai::Client.chat") do
  res = Ai::Client.chat("What is 2+2?", task_type: :factual, agent_name: "TestRunner")
  puts "Response: #{res.content.inspect}"
  raise "Empty response" if res.content.blank?
end

run_test("Ai::Client.embed (Batch)") do
  vectors = Ai::Client.embed(["Hello", "World"])
  puts "Got #{vectors.length} vectors. First vector dimension: #{vectors.first.length}"
  raise "Expected 2 vectors" unless vectors.length == 2
end

# -------------------------------------------------------------
# Test specific services
# -------------------------------------------------------------
run_test("Ai::SearchService") do
  expanded = Ai::SearchService.expand_query("HIPAA")
  puts "Expanded terms: #{expanded.inspect}"
  raise "No expansion returned" unless expanded.is_a?(Array)
end

run_test("Ai::ComplianceAssistantService") do
  res = Ai::ComplianceAssistantService.new("test_sess", user).call("How do I comply with GDPR?")
  puts "Response snippet: #{res.to_s.truncate(100).inspect}"
  raise "No chat response" if res.blank?
end

run_test("Ai::FilterAgent (Batch)") do
  candidates = [
    { title: "General Data Protection Regulation", snippet: "The GDPR is a regulation in EU law..." },
    { title: "Top 10 vacation spots in Europe", snippet: "Paris, Rome, Berlin..." }
  ]
  results = Ai::FilterAgent.new.relevant_batch?(candidates)
  puts "Batch results: #{results.inspect}"
  raise "Expected 2 results" unless results.length == 2
end

run_test("ImpactPredictionService") do
  prediction = ImpactPredictionService.new(org).predict(reg)
  puts "Prediction: #{prediction.inspect}"
  # Note: predict returns an array of hits usually or nil
end

run_test("MaturityScoringService") do
  snapshots = MaturityScoringService.new(org).snapshot_organization
  snapshot = snapshots.is_a?(Array) ? snapshots.first : snapshots
  puts "Snapshot score: #{snapshot.overall_score}, Commentary: #{snapshot.ai_commentary.to_s.truncate(100).inspect}"
  raise "Missing commentary" if snapshot.ai_commentary.blank?
end

run_test("ExecutiveReportService") do
  report = ExecutiveReportService.new(org).generate(period_start: 1.month.ago, period_end: Time.current)
  puts "Report snippet: #{report.to_s.truncate(100).inspect}"
  raise "Empty report" if report.blank?
end

run_test("PolicyGapAnalysisService") do
  draft = PolicyGapAnalysisService.new(org).analyze('Data Protection')
  puts "Policy Gap Analysis Result: #{draft.inspect}"
end

puts "\n============================================="
puts "🎉 FINISHED RUNNING TESTS"
puts "============================================="
