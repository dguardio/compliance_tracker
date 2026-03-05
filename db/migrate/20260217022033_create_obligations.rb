class CreateObligations < ActiveRecord::Migration[7.1]
  def change
    create_table :obligations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :regulation, null: true, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.integer :priority, default: 0, null: false
      t.date :due_date
      t.integer :frequency, default: 0, null: false
      t.integer :obligation_type, default: 0, null: false
      t.text :source_text
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :obligations, [:organization_id, :status]
    add_index :obligations, [:organization_id, :due_date]
  end
end
