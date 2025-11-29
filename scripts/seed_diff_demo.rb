# scripts/seed_diff_demo.rb

puts "Seeding Regulation Versions for Diff Demo..."

# 1. Create Version 1
v1_text = <<~TEXT
  SECTION 1. DATA PRIVACY
  
  (a) General Rule. All organizations must encrypt customer data at rest.
  (b) Retention. Data shall be retained for a period of 5 years.
  (c) Breach Notification. In the event of a breach, the organization must notify the affected parties within 72 hours.
  (d) Penalties. Non-compliance may result in a fine of up to $50,000.
TEXT

v1 = Regulation.create!(
  title: "Data Privacy Act 2025",
  agency: "Federal Privacy Bureau",
  jurisdiction: "US",
  reg_type: "Final Rule",
  status: "amended", # It's now amended by v2
  revision: 1,
  effective_date: 1.year.ago,
  full_text: { "extracted_content" => v1_text },
  metadata: { "summary" => "Initial version of the Data Privacy Act." }
)

puts "Created Version 1: #{v1.title} (ID: #{v1.id})"

# 2. Create Version 2 (The current version)
v2_text = <<~TEXT
  SECTION 1. DATA PRIVACY AND SECURITY
  
  (a) General Rule. All organizations must encrypt customer data at rest and in transit using AES-256 standard.
  (b) Retention. Data shall be retained for a period of 7 years.
  (c) Breach Notification. In the event of a breach, the organization must notify the affected parties and the Bureau within 24 hours.
  (d) Penalties. Non-compliance may result in a fine of up to $1,000,000 per violation.
  (e) Officer Liability. Compliance Officers may be held personally liable for willful negligence.
TEXT

v2 = Regulation.create!(
  title: "Data Privacy Act 2025 (Amended)",
  agency: "Federal Privacy Bureau",
  jurisdiction: "US",
  reg_type: "Final Rule",
  status: "active",
  revision: 2,
  effective_date: Date.today,
  previous_version: v1, # LINK TO V1
  full_text: { "extracted_content" => v2_text },
  metadata: { "summary" => "Amended version with stricter penalties and shorter notification windows." }
)

puts "Created Version 2: #{v2.title} (ID: #{v2.id})"
puts "---------------------------------------------------"
puts "To view the diff, navigate to:"
puts "/admin/regulations/#{v2.id}/diff (if route exists) or check the 'Download Diff' button on the show page."
