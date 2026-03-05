class CreateMaturityAssessments < ActiveRecord::Migration[7.1]
  def change
    # Add maturity columns to compliance_controls
    add_column :compliance_controls, :maturity_level, :integer, default: 1
    add_column :compliance_controls, :target_maturity_level, :integer, default: 3

    # Create maturity_snapshots table for historical tracking
    create_table :maturity_snapshots do |t|
      t.references :compliance_control, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.integer :maturity_level, null: false, default: 1
      t.decimal :computed_score, precision: 5, scale: 2
      t.decimal :evidence_freshness_score, precision: 5, scale: 2
      t.decimal :testing_score, precision: 5, scale: 2
      t.decimal :finding_score, precision: 5, scale: 2
      t.decimal :documentation_score, precision: 5, scale: 2
      t.date :snapshot_date, null: false

      t.timestamps
    end

    add_index :maturity_snapshots, [:compliance_control_id, :snapshot_date],
              name: 'idx_maturity_snapshots_control_date', unique: true
    add_index :maturity_snapshots, [:organization_id, :snapshot_date],
              name: 'idx_maturity_snapshots_org_date'
  end
end
