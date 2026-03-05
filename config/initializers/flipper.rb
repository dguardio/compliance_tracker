Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new
    Flipper.new(adapter)
  end
end

# Register all feature flags so they appear in Flipper UI.
# Flags are registered but NOT enabled by default.
# An admin must explicitly enable each flag per-tenant.
Rails.application.config.after_initialize do
  # Core modules (Phase 1)
  Flipper.add(:compliance_management)  # Frameworks, Requirements, Controls, Evidence
  Flipper.add(:risk_management)        # Risk Register, Heatmap, Dashboard
  Flipper.add(:document_management)    # Document Library
  Flipper.add(:policies)               # Policy Management (already in use)
  Flipper.add(:regulatory_intelligence) # Global Library, Adoption, Watchdog
  Flipper.add(:compliance_exports)     # CSV/PDF Export

  # Future modules (Phase 2–4, registered early for visibility)
  Flipper.add(:findings_remediation)   # Findings, CAPA, SLA Tracking
  Flipper.add(:control_testing)        # Test Plans, Execution, Sampling
  Flipper.add(:obligation_management)  # Obligations, Deadlines, Calendar
  Flipper.add(:incident_management)    # Incidents, Breach Reporting
  Flipper.add(:policy_attestation)     # Attestation Campaigns, Training
  Flipper.add(:evidence_freshness)     # Expiration, Refresh, Confidence
rescue ActiveRecord::StatementInvalid, ActiveRecord::NoDatabaseError => e
  # Silently skip if DB is not yet migrated (e.g., during assets:precompile)
  Rails.logger.warn "Flipper flag registration skipped: #{e.message}"
end
