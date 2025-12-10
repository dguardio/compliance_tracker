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

ActiveRecord::Schema[7.1].define(version: 2025_12_09_164846) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.index ["compliance_framework_id"], name: "index_compliance_requirements_on_compliance_framework_id"
    t.index ["organization_id"], name: "index_compliance_requirements_on_organization_id"
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
    t.index ["agency", "jurisdiction", "external_id", "revision"], name: "idx_on_agency_jurisdiction_external_id_revision_2bd25bff38", unique: true
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
  add_foreign_key "comments", "users"
  add_foreign_key "comments", "users", column: "assignee_id"
  add_foreign_key "compliance_controls", "compliance_requirements"
  add_foreign_key "compliance_controls", "organizations"
  add_foreign_key "compliance_controls", "users", column: "assignee_id"
  add_foreign_key "compliance_frameworks", "organizations"
  add_foreign_key "compliance_frameworks", "providers"
  add_foreign_key "compliance_requirements", "compliance_frameworks"
  add_foreign_key "compliance_requirements", "organizations"
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
  add_foreign_key "evidence_request_documents", "documents"
  add_foreign_key "evidence_request_documents", "evidence_requests"
  add_foreign_key "evidence_requests", "compliance_controls"
  add_foreign_key "evidence_requests", "compliance_requirements"
  add_foreign_key "evidence_requests", "organizations"
  add_foreign_key "evidence_requests", "users", column: "assigned_to_id"
  add_foreign_key "feedbacks", "users"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "organization_regulations", "compliance_frameworks"
  add_foreign_key "organization_regulations", "organizations"
  add_foreign_key "organization_regulations", "regulations"
  add_foreign_key "organization_regulations", "users", column: "assigned_by_id"
  add_foreign_key "permissions", "organizations"
  add_foreign_key "policies", "organizations"
  add_foreign_key "policy_links", "policies"
  add_foreign_key "providers", "organizations"
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
  add_foreign_key "table_templates", "organizations"
  add_foreign_key "table_templates", "users"
  add_foreign_key "teams", "departments"
  add_foreign_key "units", "teams"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "teams"
  add_foreign_key "users", "units"
  add_foreign_key "workflow_steps", "roles"
  add_foreign_key "workflow_steps", "workflow_templates"
  add_foreign_key "workflow_templates", "organizations"
  add_foreign_key "workflow_transitions", "workflow_steps"
  add_foreign_key "workflow_transitions", "workflow_steps", column: "next_step_id"
end
