class CreateImpactAssessments < ActiveRecord::Migration[7.1]
  def change
    create_table :impact_assessments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :regulation, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.integer :impacted_controls_count, default: 0
      t.integer :impacted_policies_count, default: 0
      t.decimal :estimated_effort_hours, precision: 8, scale: 1
      t.text :ai_summary
      t.jsonb :impact_details, default: {}
      t.jsonb :diff_data, default: {}
      t.references :assessed_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :impact_assessments, [:organization_id, :regulation_id]
  end
end
