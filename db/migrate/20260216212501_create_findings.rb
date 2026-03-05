class CreateFindings < ActiveRecord::Migration[7.1]
  def change
    create_table :findings do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :source, default: 0, null: false
      t.integer :severity, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.integer :root_cause, default: 0
      t.references :compliance_control, null: true, foreign_key: true
      t.references :compliance_requirement, null: true, foreign_key: true
      t.references :compliance_framework, null: true, foreign_key: true
      t.references :document, null: true, foreign_key: true
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.datetime :sla_deadline
      t.datetime :resolved_at
      t.text :resolution_notes

      t.timestamps
    end

    add_index :findings, [:organization_id, :status]
    add_index :findings, [:organization_id, :severity]
    add_index :findings, [:organization_id, :source]
  end
end
