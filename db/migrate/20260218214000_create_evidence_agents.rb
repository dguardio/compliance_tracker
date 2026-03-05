class CreateEvidenceAgents < ActiveRecord::Migration[7.1]
  def change
    # Agent credentials (encrypted connection configs)
    create_table :evidence_agent_credentials do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :provider, null: false  # github, aws, google_workspace
      t.string :label, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :encrypted_config, default: {}  # encrypted at app level
      t.datetime :last_connected_at

      t.timestamps
    end

    add_index :evidence_agent_credentials, [:organization_id, :provider]

    # Evidence collection checks
    create_table :evidence_checks do |t|
      t.references :evidence_agent_credential, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :compliance_control, null: true, foreign_key: true
      t.string :check_type, null: false  # repo_access_controls, s3_encryption, etc.
      t.integer :status, null: false, default: 0
      t.integer :last_result, default: 0  # pass, fail, error
      t.text :result_details
      t.datetime :last_run_at
      t.string :schedule  # daily, weekly, monthly

      t.timestamps
    end

    add_index :evidence_checks, [:organization_id, :status]
  end
end
