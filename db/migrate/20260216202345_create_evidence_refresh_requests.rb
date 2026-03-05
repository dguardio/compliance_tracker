class CreateEvidenceRefreshRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :evidence_refresh_requests do |t|
      t.references :document, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.string :reason
      t.integer :status, default: 0, null: false
      t.datetime :fulfilled_at
      t.references :fulfilled_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :evidence_refresh_requests, :status
  end
end
