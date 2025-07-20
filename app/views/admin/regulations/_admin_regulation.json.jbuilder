json.extract! admin_regulation, :id, :title, :agency, :jurisdiction, :reg_type, :version, :effective_date, :status, :full_text, :files, :metadata, :external_id, :previous_version_id, :created_at, :updated_at
json.url admin_regulation_url(admin_regulation, format: :json)
