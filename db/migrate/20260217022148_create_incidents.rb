class CreateIncidents < ActiveRecord::Migration[7.1]
  def change
    create_table :incidents do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :category, default: 0, null: false
      t.integer :severity, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.references :reported_by, null: true, foreign_key: { to_table: :users }
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.datetime :occurred_at
      t.datetime :detected_at
      t.datetime :resolved_at
      t.text :impact_description
      t.text :root_cause

      t.timestamps
    end

    add_index :incidents, [:organization_id, :status]
    add_index :incidents, [:organization_id, :severity]
  end
end
