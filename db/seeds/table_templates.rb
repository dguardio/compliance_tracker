puts "Creating Table Templates..."

# Clear existing templates
TableTemplate.system.destroy_all

# Define detailed templates
templates = [
  {
    name: "Legal Base Set",
    category: "legal",
    description: "Standard legal extraction columns (5 columns)",
    columns: [
      { name: "Jurisdiction", column_type: "text", prompt: "Determine the geographic or legal jurisdiction where this regulation applies (e.g. 'California', 'US Federal')." },
      { name: "Effective Date", column_type: "date", prompt: "Extract the date when this regulation becomes effective/enforceable." },
      { name: "Penalties", column_type: "text", prompt: "Extract specific monetary fines or prison terms mentioned for non-compliance." },
      { name: "Legal Basis", column_type: "text", prompt: "What specific Act, Law, or Statute provides the authority for this regulation?" },
      { name: "Summary", column_type: "text", prompt: "Provide a concise 2-sentence summary of the legal requirement." }
    ]
  },
  {
    name: "Financial Compliance",
    category: "financial",
    description: "Financial reporting and audit columns (4 columns)",
    columns: [
      { name: "Reporting Frequency", column_type: "text", prompt: "How often must reports be submitted? (e.g. Quarterly, Annually, Event-driven)" },
      { name: "Max Fine", column_type: "number", prompt: "Extract the maximum monetary fine amount as a raw number." },
      { name: "Audit Requirement", column_type: "boolean", prompt: "Does this regulation explicitly require an external audit? Return true/false." },
      { name: "Financial Impact", column_type: "text", prompt: "Describe the potential financial impact of compliance implementation." }
    ]
  },
  {
    name: "IT Security",
    category: "technical",
    description: "Cybersecurity and Data Privacy columns (6 columns)",
    columns: [
      { name: "Data Retention", column_type: "text", prompt: "Extract the specific time period data must be retained." },
      { name: "Encryption", column_type: "text", prompt: "What are the specific encryption standards required? (e.g. AES-256, TLS 1.3)" },
      { name: "Breach Notification", column_type: "text", prompt: "What is the deadline for notifying authorities/users after a breach? (e.g. 72 hours)" },
      { name: "Access Controls", column_type: "text", prompt: "Summarize the required access control measures (MFA, RBAC, etc)." },
      { name: "Data Classification", column_type: "text", prompt: "What types of data are covered? (PII, PHI, Card Data)" },
      { name: "System Scope", column_type: "text", prompt: "Which IT systems are in scope? (Servers, Endpoints, Cloud, etc)" }
    ]
  },
  {
    name: "Operational Risk",
    category: "operational",
    description: "Operational processes and risk management (3 columns)",
    columns: [
      { name: "Department Owner", column_type: "text", prompt: "Which internal department is most likely responsible? (HR, IT, Finance, Legal)" },
      { name: "Risk Level", column_type: "text", prompt: "Assess compliance risk level: High, Medium, or Low" },
      { name: "Process Change", column_type: "text", prompt: "Describe what business processes might need to change to comply." }
    ]
  }
]

templates.each do |t|
  TableTemplate.create!(
    name: t[:name],
    category: t[:category],
    description: t[:description],
    columns: t[:columns]
  )
end

puts "✓ Created #{TableTemplate.count} Table Templates."
