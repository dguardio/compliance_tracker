class CreatePolicies < ActiveRecord::Migration[7.1]
  def change
    create_table :policies do |t|
      t.string :title
      t.text :description
      t.integer :status
      t.date :effective_date
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end
  end
end
