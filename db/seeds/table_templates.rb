# db/seeds/table_templates.rb

puts "Seeding Workflow Templates..."

# Helper to create template
def create_workflow_template(name, description, category, columns)
  TableTemplate.find_or_create_by!(name: name) do |t|
    t.description = description
    t.category = category
    t.columns = columns
  end
end

# --- Legal Persona ---
create_workflow_template(
  "Legal Risk Assessment",
  "Analyze potential legal risks, penalties, and liability scope.",
  "Legal",
  [
    {
      name: "💰 Penalties & Fines",
      prompt: "What are the specific financial penalties, fines, or sanctions mentioned for non-compliance? Please extract amounts and conditions.",
      column_type: "text"
    },
    {
      name: "⚖️ Liability Scope",
      prompt: "Who is held liable for violations? (e.g., individual officers, the corporation, third parties). Extract the specific entities or roles.",
      column_type: "text"
    },
    {
      name: "📅 Effective Date",
      prompt: "What is the effective date of this regulation? Please extract the date in YYYY-MM-DD format if possible.",
      column_type: "date"
    }
  ]
)

# --- Compliance Persona ---
create_workflow_template(
  "Compliance Audit Readiness",
  "Prepare for audits by identifying reporting requirements and documentation needs.",
  "Compliance",
  [
    {
      name: "📝 Reporting Requirements",
      prompt: "What are the mandatory reporting requirements? detailed list of what must be reported, to whom, and how often.",
      column_type: "text"
    },
    {
      name: "🔍 Audit Obligations",
      prompt: "Are there requirements for internal or external audits? If so, what is the frequency and scope?",
      column_type: "text"
    },
    {
      name: "⚠️ Risk Level",
      prompt: "Based on the text, what is the implied risk level of this regulation? (High, Medium, Low). Provide a brief reasoning.",
      column_type: "text"
    }
  ]
)

# --- Technical Persona ---
create_workflow_template(
  "Technical Implementation",
  "Identify technical requirements for data handling, security, and systems.",
  "Technical",
  [
    {
      name: "💾 Data Retention",
      prompt: "What are the data retention requirements? Extract specific timeframes (e.g., '5 years', 'indefinitely') and data types.",
      column_type: "text"
    },
    {
      name: "🔒 Encryption Standards",
      prompt: "Are there specific encryption or security standards mentioned? (e.g., AES-256, TLS 1.3, 'industry standard').",
      column_type: "text"
    },
    {
      name: "🔌 API & Interop",
      prompt: "Are there requirements for APIs, data interoperability, or specific technical formats (e.g., JSON, XML)?",
      column_type: "text"
    }
  ]
)

puts "✅ Workflow Templates seeded successfully!"
