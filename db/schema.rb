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

ActiveRecord::Schema[7.1].define(version: 2025_07_15_050609) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

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
    t.bigint "organization_id", null: false
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
    t.index ["approved_by_id"], name: "index_documents_on_approved_by_id"
    t.index ["category"], name: "index_documents_on_category"
    t.index ["compliance_control_id"], name: "index_documents_on_compliance_control_id"
    t.index ["compliance_framework_id"], name: "index_documents_on_compliance_framework_id"
    t.index ["compliance_requirement_id"], name: "index_documents_on_compliance_requirement_id"
    t.index ["organization_id"], name: "index_documents_on_organization_id"
    t.index ["settings"], name: "index_documents_on_settings", using: :gin
    t.index ["status"], name: "index_documents_on_status"
    t.index ["uploaded_by_id"], name: "index_documents_on_uploaded_by_id"
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
    t.bigint "organization_id", null: false
    t.string "grantee_type", null: false
    t.bigint "grantee_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grantee_type", "grantee_id"], name: "index_permissions_on_grantee_type_and_grantee_id"
    t.index ["organization_id"], name: "index_permissions_on_organization_id"
    t.index ["resource_type", "resource_id"], name: "index_permissions_on_resource_type_and_resource_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "compliance_controls", "compliance_requirements"
  add_foreign_key "compliance_controls", "organizations"
  add_foreign_key "compliance_frameworks", "organizations"
  add_foreign_key "compliance_frameworks", "providers"
  add_foreign_key "compliance_requirements", "compliance_frameworks"
  add_foreign_key "compliance_requirements", "organizations"
  add_foreign_key "departments", "organizations"
  add_foreign_key "documents", "compliance_controls"
  add_foreign_key "documents", "compliance_frameworks"
  add_foreign_key "documents", "compliance_requirements"
  add_foreign_key "documents", "organizations"
  add_foreign_key "documents", "users", column: "approved_by_id"
  add_foreign_key "documents", "users", column: "uploaded_by_id"
  add_foreign_key "permissions", "organizations"
  add_foreign_key "providers", "organizations"
  add_foreign_key "risk_assessments", "compliance_controls"
  add_foreign_key "risk_assessments", "compliance_frameworks"
  add_foreign_key "risk_assessments", "compliance_requirements"
  add_foreign_key "risk_assessments", "organizations"
  add_foreign_key "risk_assessments", "users", column: "assigned_to_id"
  add_foreign_key "risk_assessments", "users", column: "created_by_id"
  add_foreign_key "roles", "organizations"
  add_foreign_key "teams", "departments"
  add_foreign_key "units", "teams"
  add_foreign_key "users", "departments"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "teams"
  add_foreign_key "users", "units"
end
