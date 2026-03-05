class CreateAttestations < ActiveRecord::Migration[7.1]
  def change
    create_table :attestations do |t|
      t.references :attestation_campaign, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :attested_at
      t.string :ip_address
      t.string :user_agent
      t.string :policy_version

      t.timestamps
    end

    add_index :attestations, [:attestation_campaign_id, :user_id], unique: true
    add_index :attestations, [:attestation_campaign_id, :status]
  end
end
