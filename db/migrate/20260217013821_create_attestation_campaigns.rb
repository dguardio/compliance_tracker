class CreateAttestationCampaigns < ActiveRecord::Migration[7.1]
  def change
    create_table :attestation_campaigns do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :policy, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.datetime :deadline
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :attestation_campaigns, [:organization_id, :status]
  end
end
