class CreateEvidenceRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :evidence_requests do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.date :due_date
      t.references :organization, null: false, foreign_key: true
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.references :compliance_requirement, null: true, foreign_key: true
      t.references :compliance_control, null: true, foreign_key: true

      t.timestamps
    end
  end
end
