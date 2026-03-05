class CreateTestExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :test_executions do |t|
      t.references :test_plan, null: false, foreign_key: true
      t.references :tester, null: true, foreign_key: { to_table: :users }
      t.references :reviewer, null: true, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false
      t.integer :result, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :reviewed_at
      t.text :notes
      t.text :reviewer_notes

      t.timestamps
    end

    add_index :test_executions, [:test_plan_id, :status]
  end
end
