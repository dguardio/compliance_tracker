class CreateCorrectiveActions < ActiveRecord::Migration[7.1]
  def change
    create_table :corrective_actions do |t|
      t.references :finding, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :action_type, default: 0, null: false
      t.integer :priority, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.references :assigned_to, null: true, foreign_key: { to_table: :users }
      t.references :created_by, null: true, foreign_key: { to_table: :users }
      t.datetime :due_date
      t.datetime :completed_at
      t.text :completion_notes

      t.timestamps
    end

    add_index :corrective_actions, [:finding_id, :status]
  end
end
