# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_02_21_043729) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "vector"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_agent_traces", force: :cascade do |t|
    t.string "run_id"
    t.string "agent_name"
    t.string "action"
    t.jsonb "input"
    t.text "output"
    t.jsonb "metadata"
    t.string "status"
    t.bigint "parent_trace_id"
    t.float "duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.string "model_used"
    t.decimal "estimated_cost_usd", precision: 12, scale: 8
    t.index ["agent_name"], name: "index_ai_agent_traces_on_agent_name"
    t.index ["created_at"], name: "index_ai_agent_traces_on_created_at"
    t.index ["run_id"], name: "index_ai_agent_traces_on_run_id"
  end

  create_table "attestation_campaigns", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "policy_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.datetime "deadline"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_attestation_campaigns_on_created_by_id"
    t.index ["organization_id", "status"], name: "index_attestation_campaigns_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_attestation_campaigns_on_organization_id"
    t.index ["policy_id"], name: "index_attestation_campaigns_on_policy_id"
  end

  create_table "attestations", force: :cascade do |t|
    t.bigint "attestation_campaign_id", null: false
    t.bigint "user_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "attested_at"
    t.string "ip_address"
    t.string "user_agent"
    t.string "policy_version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attestation_campaign_id", "status"], name: "index_attestations_on_attestation_campaign_id_and_status"
    t.index ["attestation_campaign_id", "user_id"], name: "index_attestations_on_attestation_campaign_id_and_user_id", unique: true
    t.index ["attestation_campaign_id"], name: "index_attestations_on_attestation_campaign_id"
    t.index ["user_id"], name: "index_attestations_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.text "content"
    t.text "selected_text"
    t.integer "start_index"
    t.integer "end_index"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "comment_type", default: "comment"
    t.text "suggested_text"
    t.bigint "assignee_id"
    t.index ["assignee_id"], name: "index_comments_on_assignee_id"
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "compliance_controls", force: :cascade do |t|
    t.string "name"
    t.integer "control_type"
    t.text "description"
    t.integer "effectiveness"
    t.integer "status"
    t.bigint "compliance_requirement_id", null: false
    t.bigint "organization_id", null: false
    t.jsonb "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "risk_level"
    t.bigint "assignee_id"
    t.date "due_date"
    t.integer "maturity_level", default: 1
    t.integer "target_maturity_level", default: 3
    t.index ["assignee_id"], name: "index_compliance_controls_on_assignee_id"
    t.index ["compliance_requirement_id"], name: "index_compliance_controls_on_compliance_requirement_id"
    t.index ["organization_id"], name: "index_compliance_controls_on_organization_id"
  end

  create_table "compliance_frameworks", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.string "version"
    t.integer "status"
    t.bigint "organization_id", null: false
    t.jsonb "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "issuance_type"
    t.date "publication_date"
    t.string "provider_url"
    t.date "enforcement_date"
    t.text "potentially_impacted_departments"
    t.bigint "provider_id"
    t.index ["organization_id"], name: "index_compliance_frameworks_on_organization_id"
    t.index ["provider_id"], name: "index_compliance_frameworks_on_provider_id"
  end

  create_table "compliance_requirements", force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.text "description"
    t.integer "requirement_type"
    t.integer "priority"
    t.integer "status"
    t.bigint "compliance_framework_id", null: false
    t.bigint "organization_id", null: false
    t.jsonb "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "risk_level"
    t.bigint "standard_requirement_id", null: false
    t.index ["compliance_framework_id"], name: "index_compliance_requirements_on_compliance_framework_id"
    t.index ["organization_id"], name: "index_compliance_requirements_on_organization_id"
    t.index ["standard_requirement_id"], name: "index_compliance_requirements_on_standard_requirement_id"
  end

  create_table "corrective_actions", force: :cascade do |t|
    t.bigint "finding_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "action_type", default: 0, null: false
    t.integer "priority", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.bigint "assigned_to_id"
    t.bigint "created_by_id"
    t.datetime "due_date"
    t.datetime "completed_at"
    t.text "completion_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_corrective_actions_on_assigned_to_id"
    t.index ["created_by_id"], name: "index_corrective_actions_on_created_by_id"
    t.index ["finding_id", "status"], name: "index_corrective_actions_on_finding_id_and_status"
    t.index ["finding_id"], name: "index_corrective_actions_on_finding_id"
  end

  create_table "custom_columns", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "prompt", null: false
    t.string "column_type", default: "text"
    t.boolean "is_template", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_custom_columns_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_custom_columns_on_user_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.bigint "organization_id", null: false
    t.jsonb "settings"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_departments_on_organization_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "category"
    t.integer "status", default: 0
    t.bigint "organization_id"
    t.bigint "compliance_framework_id"
    t.bigint "compliance_requirement_id"
    t.bigint "compliance_control_id"
    t.bigint "uploaded_by_id", null: false
    t.bigint "approved_by_id"
    t.datetime "approved_at"
    t.datetime "expires_at"
    t.integer "version", default: 1
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "regulation_id"
    t.bigint "workflow_template_id"
    t.index ["approved_by_id"], name: "index_documents_on_approved_by_id"
    t.index ["category"], name: "index_documents_on_category"
    t.index ["compliance_control_id"], name: "index_documents_on_compliance_control_id"
    t.index ["compliance_framework_id"], name: "index_documents_on_compliance_framework_id"
    t.index ["compliance_requirement_id"], name: "index_documents_on_compliance_requirement_id"
    t.index ["organization_id"], name: "index_documents_on_organization_id"
    t.index ["regulation_id"], name: "index_documents_on_regulation_id"
    t.index ["settings"], name: "index_documents_on_settings", using: :gin
    t.index ["status"], name: "index_documents_on_status"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
    t.index ["workflow_template_id"], name: "index_documents_on_workflow_template_id"
  end

  create_table "evidence_agent_credentials", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "provider", null: false
    t.string "label", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "encrypted_config", default: {}
    t.datetime "last_connected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "provider"], name: "idx_on_organization_id_provider_732377cb73"
    t.index ["organization_id"], name: "index_evidence_agent_credentials_on_organization_id"
  end

  create_table "evidence_checks", force: :cascade do |t|
    t.bigint "evidence_agent_credential_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "compliance_control_id"
    t.string "check_type", null: false
    t.integer "status", default: 0, null: false
    t.integer "last_result", default: 0
    t.text "result_details"
    t.datetime "last_run_at"
    t.string "schedule"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["compliance_control_id"], name: "index_evidence_checks_on_compliance_control_id"
    t.index ["evidence_agent_credential_id"], name: "index_evidence_checks_on_evidence_agent_credential_id"
    t.index ["organization_id", "status"], name: "index_evidence_checks_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_evidence_checks_on_organization_id"
  end

  create_table "evidence_refresh_requests", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "requester_id", null: false
    t.string "reason"
    t.integer "status", default: 0, null: false
    t.datetime "fulfilled_at"
    t.bigint "fulfilled_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_evidence_refresh_requests_on_document_id"
    t.index ["fulfilled_by_id"], name: "index_evidence_refresh_requests_on_fulfilled_by_id"
    t.index ["requester_id"], name: "index_evidence_refresh_requests_on_requester_id"
    t.index ["status"], name: "index_evidence_refresh_requests_on_status"
  end

  create_table "evidence_request_documents", force: :cascade do |t|
    t.bigint "evidence_request_id", null: false
    t.bigint "document_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_evidence_request_documents_on_document_id"
    t.index ["evidence_request_id"], name: "index_evidence_request_documents_on_evidence_request_id"
  end

  create_table "evidence_requests", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "status"
    t.date "due_date"
    t.bigint "organization_id", null: false
    t.bigint "assigned_to_id"
    t.bigint "compliance_requirement_id"
    t.bigint "compliance_control_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_evidence_requests_on_assigned_to_id"
    t.index ["compliance_control_id"], name: "index_evidence_requests_on_compliance_control_id"
    t.index ["compliance_requirement_id"], name: "index_evidence_requests_on_compliance_requirement_id"
    t.index ["organization_id"], name: "index_evidence_requests_on_organization_id"
  end

  create_table "executive_reports", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.integer "report_type", default: 0, null: false
    t.date "period_start"
    t.date "period_end"
    t.text "narrative"
    t.jsonb "metrics", default: {}
    t.integer "status", default: 0, null: false
    t.bigint "generated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["generated_by_id"], name: "index_executive_reports_on_generated_by_id"
    t.index ["organization_id", "report_type"], name: "index_executive_reports_on_organization_id_and_report_type"
    t.index ["organization_id"], name: "index_executive_reports_on_organization_id"
  end

  create_table "external_integrations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "provider", null: false
    t.string "label", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "config", default: {}
    t.jsonb "encrypted_credentials", default: {}
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "provider"], name: "index_external_integrations_on_organization_id_and_provider"
    t.index ["organization_id"], name: "index_external_integrations_on_organization_id"
  end

  create_table "external_tickets", force: :cascade do |t|
    t.bigint "external_integration_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "finding_id"
    t.bigint "incident_id"
    t.string "external_id", null: false
    t.string "external_url"
    t.string "external_status"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_integration_id", "external_id"], name: "idx_ext_tickets_integration_ext_id", unique: true
    t.index ["external_integration_id"], name: "index_external_tickets_on_external_integration_id"
    t.index ["finding_id"], name: "index_external_tickets_on_finding_id"
    t.index ["incident_id"], name: "index_external_tickets_on_incident_id"
    t.index ["organization_id"], name: "index_external_tickets_on_organization_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "feedbackable_type", null: false
    t.bigint "feedbackable_id", null: false
    t.text "content", null: false
    t.string "status", default: "open", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feedbackable_type", "feedbackable_id"], name: "index_feedbacks_on_feedbackable"
    t.index ["user_id"], name: "index_feedbacks_on_user_id"
  end

  create_table "findings", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "source", default: 0, null: false
    t.integer "severity", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "root_cause", default: 0
    t.bigint "compliance_control_id"
    t.bigint "compliance_requirement_id"
    t.bigint "compliance_framework_id"
    t.bigint "document_id"
    t.bigint "assigned_to_id"
    t.bigint "created_by_id"
    t.datetime "sla_deadline"
    t.datetime "resolved_at"
    t.text "resolution_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_findings_on_assigned_to_id"
    t.index ["compliance_control_id"], name: "index_findings_on_compliance_control_id"
    t.index ["compliance_framework_id"], name: "index_findings_on_compliance_framework_id"
    t.index ["compliance_requirement_id"], name: "index_findings_on_compliance_requirement_id"
    t.index ["created_by_id"], name: "index_findings_on_created_by_id"
    t.index ["document_id"], name: "index_findings_on_document_id"
    t.index ["organization_id", "severity"], name: "index_findings_on_organization_id_and_severity"
    t.index ["organization_id", "source"], name: "index_findings_on_organization_id_and_source"
    t.index ["organization_id", "status"], name: "index_findings_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_findings_on_organization_id"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "framework_mappings", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "source_requirement_id", null: false
    t.bigint "target_requirement_id", null: false
    t.integer "mapping_type", default: 0, null: false
    t.decimal "confidence", precision: 5, scale: 2
    t.boolean "ai_generated", default: false
    t.text "rationale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "mapping_type"], name: "idx_framework_mappings_org_type"
    t.index ["organization_id"], name: "index_framework_mappings_on_organization_id"
    t.index ["source_requirement_id", "target_requirement_id"], name: "idx_framework_mappings_src_tgt", unique: true
    t.index ["source_requirement_id"], name: "index_framework_mappings_on_source_requirement_id"
    t.index ["target_requirement_id"], name: "index_framework_mappings_on_target_requirement_id"
  end

  create_table "impact_assessments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "regulation_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "impacted_controls_count", default: 0
    t.integer "impacted_policies_count", default: 0
    t.decimal "estimated_effort_hours", precision: 8, scale: 1
    t.text "ai_summary"
    t.jsonb "impact_details", default: {}
    t.jsonb "diff_data", default: {}
    t.bigint "assessed_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessed_by_id"], name: "index_impact_assessments_on_assessed_by_id"
    t.index ["organization_id", "regulation_id"], name: "index_impact_assessments_on_organization_id_and_regulation_id"
    t.index ["organization_id"], name: "index_impact_assessments_on_organization_id"
    t.index ["regulation_id"], name: "index_impact_assessments_on_regulation_id"
  end

  create_table "incidents", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "category", default: 0, null: false
    t.integer "severity", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.bigint "reported_by_id"
    t.bigint "assigned_to_id"
    t.datetime "occurred_at"
    t.datetime "detected_at"
    t.datetime "resolved_at"
    t.text "impact_description"
    t.text "root_cause"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_incidents_on_assigned_to_id"
    t.index ["organization_id", "severity"], name: "index_incidents_on_organization_id_and_severity"
    t.index ["organization_id", "status"], name: "index_incidents_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_incidents_on_organization_id"
    t.index ["reported_by_id"], name: "index_incidents_on_reported_by_id"
  end

  create_table "lesson_learneds", force: :cascade do |t|
    t.bigint "incident_id", null: false
    t.string "title", null: false
    t.text "description"
    t.text "recommendations"
    t.integer "category", default: 0, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_lesson_learneds_on_created_by_id"
    t.index ["incident_id"], name: "index_lesson_learneds_on_incident_id"
  end

  create_table "maturity_snapshots", force: :cascade do |t|
    t.bigint "compliance_control_id", null: false
    t.bigint "organization_id", null: false
    t.integer "maturity_level", default: 1, null: false
    t.decimal "computed_score", precision: 5, scale: 2
    t.decimal "evidence_freshness_score", precision: 5, scale: 2
    t.decimal "testing_score", precision: 5, scale: 2
    t.decimal "finding_score", precision: 5, scale: 2
    t.decimal "documentation_score", precision: 5, scale: 2
    t.date "snapshot_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "ai_commentary"
    t.index ["compliance_control_id", "snapshot_date"], name: "idx_maturity_snapshots_control_date", unique: true
    t.index ["compliance_control_id"], name: "index_maturity_snapshots_on_compliance_control_id"
    t.index ["organization_id", "snapshot_date"], name: "idx_maturity_snapshots_org_date"
    t.index ["organization_id"], name: "index_maturity_snapshots_on_organization_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "role"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "noticed_events", force: :cascade do |t|
    t.string "type"
    t.string "record_type"
    t.bigint "record_id"
    t.jsonb "params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "notifications_count"
    t.index ["record_type", "record_id"], name: "index_noticed_events_on_record"
  end

  create_table "noticed_notifications", force: :cascade do |t|
    t.string "type"
    t.bigint "event_id", null: false
    t.string "recipient_type", null: false
    t.bigint "recipient_id", null: false
    t.datetime "read_at", precision: nil
    t.datetime "seen_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_noticed_notifications_on_event_id"
    t.index ["recipient_type", "recipient_id"], name: "index_noticed_notifications_on_recipient"
  end

  create_table "obligation_controls", force: :cascade do |t|
    t.bigint "obligation_id", null: false
    t.bigint "compliance_control_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["compliance_control_id"], name: "index_obligation_controls_on_compliance_control_id"
    t.index ["obligation_id", "compliance_control_id"], name: "idx_obligation_controls_unique", unique: true
    t.index ["obligation_id"], name: "index_obligation_controls_on_obligation_id"
  end

  create_table "obligations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "regulation_id"
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "priority", default: 0, null: false
    t.date "due_date"
    t.integer "frequency", default: 0, null: false
    t.integer "obligation_type", default: 0, null: false
    t.text "source_text"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_obligations_on_created_by_id"
    t.index ["organization_id", "due_date"], name: "index_obligations_on_organization_id_and_due_date"
    t.index ["organization_id", "status"], name: "index_obligations_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_obligations_on_organization_id"
    t.index ["regulation_id"], name: "index_obligations_on_regulation_id"
  end

  create_table "organization_regulations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "regulation_id", null: false
    t.bigint "compliance_framework_id"
    t.integer "priority", default: 0
    t.string "status", default: "pending"
    t.datetime "assigned_at"
    t.bigint "assigned_by_id"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_organization_regulations_on_assigned_by_id"
    t.index ["compliance_framework_id"], name: "index_organization_regulations_on_compliance_framework_id"
    t.index ["organization_id", "priority"], name: "index_organization_regulations_on_organization_id_and_priority"
    t.index ["organization_id", "regulation_id"], name: "index_org_regs_on_org_and_reg_unique", unique: true
    t.index ["organization_id", "status"], name: "index_organization_regulations_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_organization_regulations_on_organization_id"
    t.index ["regulation_id", "status"], name: "index_organization_regulations_on_regulation_id_and_status"
    t.index ["regulation_id"], name: "index_organization_regulations_on_regulation_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.string "domain"
    t.jsonb "settings"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "permissions", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.string "action"
    t.jsonb "conditions"
    t.bigint "organization_id"
    t.string "grantee_type", null: false
    t.bigint "grantee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grantee_type", "grantee_id"], name: "index_permissions_on_grantee_type_and_grantee_id"
    t.index ["organization_id"], name: "index_permissions_on_organization_id"
    t.index ["resource_type", "resource_id"], name: "index_permissions_on_resource_type_and_resource_id"
  end

  create_table "policies", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "status"
    t.date "effective_date"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_policies_on_organization_id"
  end

  create_table "policy_links", force: :cascade do |t|
    t.bigint "policy_id", null: false
    t.string "linkable_type", null: false
    t.bigint "linkable_id", null: false
    t.string "citation"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["linkable_type", "linkable_id"], name: "index_policy_links_on_linkable"
    t.index ["policy_id"], name: "index_policy_links_on_policy_id"
  end

  create_table "providers", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.text "description"
    t.string "website"
    t.string "jurisdiction", null: false
    t.string "state"
    t.string "country", null: false
    t.jsonb "contact_info", default: {}
    t.jsonb "settings", default: {}
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "provider_type"
    t.bigint "organization_id"
    t.index ["code"], name: "index_providers_on_code", unique: true
    t.index ["country"], name: "index_providers_on_country"
    t.index ["jurisdiction"], name: "index_providers_on_jurisdiction"
    t.index ["name"], name: "index_providers_on_name"
    t.index ["organization_id"], name: "index_providers_on_organization_id"
    t.index ["settings"], name: "index_providers_on_settings", using: :gin
    t.index ["status"], name: "index_providers_on_status"
  end

  create_table "questionnaire_answers", force: :cascade do |t|
    t.bigint "questionnaire_upload_id", null: false
    t.text "question_text", null: false
    t.text "ai_answer"
    t.text "approved_answer"
    t.decimal "confidence", precision: 5, scale: 2
    t.bigint "source_policy_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["questionnaire_upload_id", "status"], name: "idx_on_questionnaire_upload_id_status_ccfcea4965"
    t.index ["questionnaire_upload_id"], name: "index_questionnaire_answers_on_questionnaire_upload_id"
    t.index ["source_policy_id"], name: "index_questionnaire_answers_on_source_policy_id"
  end

  create_table "questionnaire_uploads", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "uploaded_by_id"
    t.string "filename", null: false
    t.integer "status", default: 0, null: false
    t.integer "response_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_questionnaire_uploads_on_organization_id"
    t.index ["uploaded_by_id"], name: "index_questionnaire_uploads_on_uploaded_by_id"
  end

  create_table "regulation_extractions", force: :cascade do |t|
    t.bigint "regulation_id", null: false
    t.bigint "custom_column_id", null: false
    t.text "extracted_value"
    t.text "reasoning"
    t.text "source_text"
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["custom_column_id"], name: "index_regulation_extractions_on_custom_column_id"
    t.index ["regulation_id", "custom_column_id"], name: "index_reg_extractions_on_reg_and_column", unique: true
    t.index ["regulation_id"], name: "index_regulation_extractions_on_regulation_id"
  end

  create_table "regulation_review_decisions", force: :cascade do |t|
    t.bigint "regulation_review_id", null: false
    t.bigint "workflow_step_id", null: false
    t.bigint "user_id", null: false
    t.string "decision", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["regulation_review_id"], name: "index_regulation_review_decisions_on_regulation_review_id"
    t.index ["user_id"], name: "index_regulation_review_decisions_on_user_id"
    t.index ["workflow_step_id"], name: "index_regulation_review_decisions_on_workflow_step_id"
  end

  create_table "regulation_reviews", force: :cascade do |t|
    t.bigint "organization_regulation_id", null: false
    t.bigint "workflow_template_id", null: false
    t.string "workflow_state", null: false
    t.string "status", default: "in_progress", null: false
    t.bigint "assignee_id"
    t.datetime "completed_at"
    t.text "decision_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id"], name: "index_regulation_reviews_on_assignee_id"
    t.index ["organization_regulation_id"], name: "index_regulation_reviews_on_organization_regulation_id", unique: true
    t.index ["status"], name: "index_regulation_reviews_on_status"
    t.index ["workflow_state"], name: "index_regulation_reviews_on_workflow_state"
    t.index ["workflow_template_id"], name: "index_regulation_reviews_on_workflow_template_id"
  end

  create_table "regulations", force: :cascade do |t|
    t.string "external_id"
    t.string "title", null: false
    t.string "agency", null: false
    t.string "jurisdiction", null: false
    t.string "reg_type"
    t.date "effective_date"
    t.date "publication_date"
    t.string "status"
    t.integer "revision", default: 1
    t.bigint "previous_version_id"
    t.jsonb "full_text", default: {}
    t.jsonb "files", default: {}
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.vector "embedding", limit: 768
    t.index ["agency", "jurisdiction", "external_id", "revision"], name: "idx_on_agency_jurisdiction_external_id_revision_2bd25bff38", unique: true
    t.index ["embedding"], name: "index_regulations_on_embedding", opclass: :vector_l2_ops, using: :hnsw
    t.index ["external_id"], name: "index_regulations_on_external_id"
    t.index ["previous_version_id"], name: "index_regulations_on_previous_version_id"
  end

  create_table "regulatory_data_sources", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "source_type", null: false
    t.string "url", null: false
    t.integer "status", default: 0, null: false
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "provider_id", null: false
    t.jsonb "sectors", default: []
    t.jsonb "jurisdictions", default: []
    t.string "documentation_url"
    t.text "documentation_content"
    t.text "api_key"
    t.string "api_key_param"
    t.datetime "last_synced_at"
    t.index ["name"], name: "index_regulatory_data_sources_on_name", unique: true
    t.index ["provider_id"], name: "index_regulatory_data_sources_on_provider_id"
    t.index ["source_type"], name: "index_regulatory_data_sources_on_source_type"
    t.index ["status"], name: "index_regulatory_data_sources_on_status"
  end

  create_table "risk_assessments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "compliance_framework_id", null: false
    t.bigint "compliance_requirement_id", null: false
    t.bigint "compliance_control_id", null: false
    t.string "name"
    t.text "description"
    t.integer "likelihood"
    t.integer "impact"
    t.integer "risk_score"
    t.integer "status"
    t.date "assessment_date"
    t.date "next_review_date"
    t.text "mitigation_plan"
    t.bigint "created_by_id", null: false
    t.bigint "assigned_to_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_to_id"], name: "index_risk_assessments_on_assigned_to_id"
    t.index ["compliance_control_id"], name: "index_risk_assessments_on_compliance_control_id"
    t.index ["compliance_framework_id"], name: "index_risk_assessments_on_compliance_framework_id"
    t.index ["compliance_requirement_id"], name: "index_risk_assessments_on_compliance_requirement_id"
    t.index ["created_by_id"], name: "index_risk_assessments_on_created_by_id"
    t.index ["organization_id"], name: "index_risk_assessments_on_organization_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["organization_id"], name: "index_roles_on_organization_id"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "standard_requirements", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "regulation_id", null: false
    t.string "category"
    t.string "external_id"
    t.vector "embedding", limit: 768
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["embedding"], name: "index_standard_requirements_on_embedding", opclass: :vector_l2_ops, using: :hnsw
    t.index ["regulation_id"], name: "index_standard_requirements_on_regulation_id"
  end

  create_table "table_templates", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "category"
    t.jsonb "columns"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "organization_id"
    t.index ["organization_id"], name: "index_table_templates_on_organization_id"
    t.index ["user_id"], name: "index_table_templates_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.bigint "department_id", null: false
    t.jsonb "settings"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department_id"], name: "index_teams_on_department_id"
  end

  create_table "test_executions", force: :cascade do |t|
    t.bigint "test_plan_id", null: false
    t.bigint "tester_id"
    t.bigint "reviewer_id"
    t.integer "status", default: 0, null: false
    t.integer "result", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "reviewed_at"
    t.text "notes"
    t.text "reviewer_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewer_id"], name: "index_test_executions_on_reviewer_id"
    t.index ["test_plan_id", "status"], name: "index_test_executions_on_test_plan_id_and_status"
    t.index ["test_plan_id"], name: "index_test_executions_on_test_plan_id"
    t.index ["tester_id"], name: "index_test_executions_on_tester_id"
  end

  create_table "test_plans", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "compliance_control_id", null: false
    t.string "title", null: false
    t.text "description"
    t.integer "frequency", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "procedures"
    t.date "next_due_date"
    t.datetime "last_tested_at"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["compliance_control_id"], name: "index_test_plans_on_compliance_control_id"
    t.index ["created_by_id"], name: "index_test_plans_on_created_by_id"
    t.index ["organization_id", "next_due_date"], name: "index_test_plans_on_organization_id_and_next_due_date"
    t.index ["organization_id", "status"], name: "index_test_plans_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_test_plans_on_organization_id"
  end

  create_table "test_samples", force: :cascade do |t|
    t.bigint "test_execution_id", null: false
    t.string "sample_identifier", null: false
    t.integer "result", default: 0, null: false
    t.text "notes"
    t.text "evidence_notes"
    t.datetime "tested_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["test_execution_id"], name: "index_test_samples_on_test_execution_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.bigint "team_id", null: false
    t.jsonb "settings"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_units_on_team_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.bigint "department_id"
    t.bigint "team_id"
    t.bigint "unit_id"
    t.jsonb "settings", default: {}
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.index ["department_id"], name: "index_users_on_department_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["team_id"], name: "index_users_on_team_id"
    t.index ["unit_id"], name: "index_users_on_unit_id"
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "vendor_assessments", force: :cascade do |t|
    t.bigint "vendor_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "assessed_by_id"
    t.integer "assessment_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "risk_score"
    t.date "assessment_date"
    t.date "next_review_date"
    t.text "notes"
    t.jsonb "questionnaire_responses", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assessed_by_id"], name: "index_vendor_assessments_on_assessed_by_id"
    t.index ["organization_id"], name: "index_vendor_assessments_on_organization_id"
    t.index ["vendor_id", "assessment_date"], name: "index_vendor_assessments_on_vendor_id_and_assessment_date"
    t.index ["vendor_id"], name: "index_vendor_assessments_on_vendor_id"
  end

  create_table "vendors", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "website"
    t.integer "risk_tier", default: 2, null: false
    t.integer "status", default: 0, null: false
    t.text "description"
    t.string "primary_contact_name"
    t.string "primary_contact_email"
    t.date "contract_start"
    t.date "contract_end"
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_vendors_on_organization_id_and_name", unique: true
    t.index ["organization_id", "risk_tier"], name: "index_vendors_on_organization_id_and_risk_tier"
    t.index ["organization_id"], name: "index_vendors_on_organization_id"
  end

  create_table "versions", force: :cascade do |t|
    t.string "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.text "object"
    t.text "object_changes"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "workflow_steps", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "workflow_template_id", null: false
    t.bigint "role_id", null: false
    t.string "step_type", null: false
    t.text "description"
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "decision_options", default: []
    t.integer "position_x"
    t.integer "position_y"
    t.index ["role_id"], name: "index_workflow_steps_on_role_id"
    t.index ["workflow_template_id"], name: "index_workflow_steps_on_workflow_template_id"
  end

  create_table "workflow_templates", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.boolean "is_default", default: false, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_workflow_templates_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_workflow_templates_on_organization_id"
  end

  create_table "workflow_transitions", force: :cascade do |t|
    t.bigint "workflow_step_id", null: false
    t.bigint "next_step_id", null: false
    t.string "condition"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source_anchor_type"
    t.string "target_anchor_type"
    t.index ["next_step_id"], name: "index_workflow_transitions_on_next_step_id"
    t.index ["workflow_step_id"], name: "index_workflow_transitions_on_workflow_step_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "attestation_campaigns", "organizations"
  add_foreign_key "attestation_campaigns", "policies"
  add_foreign_key "attestation_campaigns", "users", column: "created_by_id"
  add_foreign_key "attestations", "attestation_campaigns"
  add_foreign_key "attestations", "users"
  add_foreign_key "comments", "users"
  add_foreign_key "comments", "users", column: "assignee_id"
  add_foreign_key "compliance_controls", "compliance_requirements"
  add_foreign_key "compliance_controls", "organizations"
  add_foreign_key "compliance_controls", "users", column: "assignee_id"
  add_foreign_key "compliance_frameworks", "organizations"
  add_foreign_key "compliance_frameworks", "providers"
  add_foreign_key "compliance_requirements", "compliance_frameworks"
  add_foreign_key "compliance_requirements", "organizations"
  add_foreign_key "compliance_requirements", "standard_requirements"
  add_foreign_key "corrective_actions", "findings"
  add_foreign_key "corrective_actions", "users", column: "assigned_to_id"
  add_foreign_key "corrective_actions", "users", column: "created_by_id"
  add_foreign_key "custom_columns", "users"
  add_foreign_key "departments", "organizations"
  add_foreign_key "documents", "compliance_controls"
  add_foreign_key "documents", "compliance_frameworks"
  add_foreign_key "documents", "compliance_requirements"
  add_foreign_key "documents", "organizations"
  add_foreign_key "documents", "regulations"
  add_foreign_key "documents", "users", column: "approved_by_id"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "documents", "workflow_templates"
  add_foreign_key "evidence_agent_credentials", "organizations"
  add_foreign_key "evidence_checks", "compliance_controls"
  add_foreign_key "evidence_checks", "evidence_agent_credentials"
  add_foreign_key "evidence_checks", "organizations"
  add_foreign_key "evidence_refresh_requests", "documents"
  add_foreign_key "evidence_refresh_requests", "users", column: "fulfilled_by_id"
  add_foreign_key "evidence_refresh_requests", "users", column: "requester_id"
  add_foreign_key "evidence_request_documents", "documents"
  add_foreign_key "evidence_request_documents", "evidence_requests"
  add_foreign_key "evidence_requests", "compliance_controls"
  add_foreign_key "evidence_requests", "compliance_requirements"
  add_foreign_key "evidence_requests", "organizations"
  add_foreign_key "evidence_requests", "users", column: "assigned_to_id"
  add_foreign_key "executive_reports", "organizations"
  add_foreign_key "executive_reports", "users", column: "generated_by_id"
  add_foreign_key "external_integrations", "organizations"
  add_foreign_key "external_tickets", "external_integrations"
  add_foreign_key "external_tickets", "findings"
  add_foreign_key "external_tickets", "incidents"
  add_foreign_key "external_tickets", "organizations"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "findings", "compliance_controls"
  add_foreign_key "findings", "compliance_frameworks"
  add_foreign_key "findings", "compliance_requirements"
  add_foreign_key "findings", "documents"
  add_foreign_key "findings", "organizations"
  add_foreign_key "findings", "users", column: "assigned_to_id"
  add_foreign_key "findings", "users", column: "created_by_id"
  add_foreign_key "framework_mappings", "compliance_requirements", column: "source_requirement_id"
  add_foreign_key "framework_mappings", "compliance_requirements", column: "target_requirement_id"
  add_foreign_key "framework_mappings", "organizations"
  add_foreign_key "impact_assessments", "organizations"
  add_foreign_key "impact_assessments", "regulations"
  add_foreign_key "impact_assessments", "users", column: "assessed_by_id"
  add_foreign_key "incidents", "organizations"
  add_foreign_key "incidents", "users", column: "assigned_to_id"
  add_foreign_key "incidents", "users", column: "reported_by_id"
  add_foreign_key "lesson_learneds", "incidents"
  add_foreign_key "lesson_learneds", "users", column: "created_by_id"
  add_foreign_key "maturity_snapshots", "compliance_controls"
  add_foreign_key "maturity_snapshots", "organizations"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "obligation_controls", "compliance_controls"
  add_foreign_key "obligation_controls", "obligations"
  add_foreign_key "obligations", "organizations"
  add_foreign_key "obligations", "regulations"
  add_foreign_key "obligations", "users", column: "created_by_id"
  add_foreign_key "organization_regulations", "compliance_frameworks"
  add_foreign_key "organization_regulations", "organizations"
  add_foreign_key "organization_regulations", "regulations"
  add_foreign_key "organization_regulations", "users", column: "assigned_by_id"
  add_foreign_key "permissions", "organizations"
  add_foreign_key "policies", "organizations"
  add_foreign_key "policy_links", "policies"
  add_foreign_key "providers", "organizations"
  add_foreign_key "questionnaire_answers", "policies", column: "source_policy_id"
  add_foreign_key "questionnaire_answers", "questionnaire_uploads"
  add_foreign_key "questionnaire_uploads", "organizations"
  add_foreign_key "questionnaire_uploads", "users", column: "uploaded_by_id"
  add_foreign_key "regulation_extractions", "custom_columns"
  add_foreign_key "regulation_extractions", "regulations"
  add_foreign_key "regulation_review_decisions", "regulation_reviews"
  add_foreign_key "regulation_review_decisions", "users"
  add_foreign_key "regulation_review_decisions", "workflow_steps"
  add_foreign_key "regulation_reviews", "organization_regulations"
  add_foreign_key "regulation_reviews", "users", column: "assignee_id"
  add_foreign_key "regulation_reviews", "workflow_templates"
  add_foreign_key "regulations", "regulations", column: "previous_version_id"
  add_foreign_key "regulatory_data_sources", "providers"
  add_foreign_key "risk_assessments", "compliance_controls"
  add_foreign_key "risk_assessments", "compliance_frameworks"
  add_foreign_key "risk_assessments", "compliance_requirements"
  add_foreign_key "risk_assessments", "organizations"
  add_foreign_key "risk_assessments", "users", column: "assigned_to_id"
  add_foreign_key "risk_assessments", "users", column: "created_by_id"
  add_foreign_key "roles", "organizations"
  add_foreign_key "standard_requirements", "regulations"
  add_foreign_key "table_templates", "organizations"
  add_foreign_key "table_templates", "users"
  add_foreign_key "teams", "departments"
  add_foreign_key "test_executions", "test_plans"
  add_foreign_key "test_executions", "users", column: "reviewer_id"
  add_foreign_key "test_executions", "users", column: "tester_id"
  add_foreign_key "test_plans", "compliance_controls"
  add_foreign_key "test_plans", "organizations"
  add_foreign_key "test_plans", "users", column: "created_by_id"
  add_foreign_key "test_samples", "test_executions"
  add_foreign_key "units", "teams"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "teams"
  add_foreign_key "users", "units"
  add_foreign_key "vendor_assessments", "organizations"
  add_foreign_key "vendor_assessments", "users", column: "assessed_by_id"
  add_foreign_key "vendor_assessments", "vendors"
  add_foreign_key "vendors", "organizations"
  add_foreign_key "workflow_steps", "roles"
  add_foreign_key "workflow_steps", "workflow_templates"
  add_foreign_key "workflow_templates", "organizations"
  add_foreign_key "workflow_transitions", "workflow_steps"
  add_foreign_key "workflow_transitions", "workflow_steps", column: "next_step_id"
end
