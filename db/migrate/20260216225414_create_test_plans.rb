class CreateTestPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :test_plans do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :compliance_control, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :frequency, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.text :procedures
      t.date :next_due_date
      t.datetime :last_tested_at
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :test_plans, [:organization_id, :status]
    add_index :test_plans, [:organization_id, :next_due_date]
  end
end
