class CreateExternalIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :external_integrations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :provider, null: false  # jira, linear, servicenow
      t.string :label, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :config, default: {}  # base URL, project ID, etc.
      t.jsonb :encrypted_credentials, default: {}
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :external_integrations, [:organization_id, :provider]

    create_table :external_tickets do |t|
      t.references :external_integration, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :finding, null: true, foreign_key: true
      t.references :incident, null: true, foreign_key: true
      t.string :external_id, null: false
      t.string :external_url
      t.string :external_status
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :external_tickets, [:external_integration_id, :external_id], unique: true, name: 'idx_ext_tickets_integration_ext_id'
  end
end
