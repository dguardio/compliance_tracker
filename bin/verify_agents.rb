#!/usr/bin/env rails runner

puts "\n=== Starting Virtual Compliance Officer Verification ==="

intention = "Draft a very short Guest Wi-Fi Usage Policy"
puts "\n[1] User Intention: \"#{intention}\""

# Measure time
start_time = Time.now

# Execute Orchestrator
puts "[2] Calling Ai::OrchestratorAgent..."
result = Ai::OrchestratorAgent.new.execute(intention: intention)

duration = (Time.now - start_time).round(2)

puts "\n[3] Orchestrator Finished in #{duration}s"
puts "\n=== RESULT SUMMARY ==="
puts "Topic: #{result[:topic]}"
puts "Review Score: #{result[:review_score]}/100"

puts "\n--- Draft Preview (First 200 chars) ---"
puts result[:draft_content][0..200] + "..."

puts "\n--- Review Findings ---"
if result[:review_findings].any?
  result[:review_findings].first(2).each do |finding|
    puts "- [#{finding[:severity]}] #{finding[:issue]}"
  end
else
  puts "No major findings."
end

puts "\n=== Verification Complete ==="
