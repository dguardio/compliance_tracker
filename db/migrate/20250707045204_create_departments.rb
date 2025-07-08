class CreateDepartments < ActiveRecord::Migration[7.1]
  def change
    create_table :departments do |t|
      t.string :name
      t.string :slug
      t.references :organization, null: false, foreign_key: true
      t.jsonb :settings
      t.integer :status

      t.timestamps
    end
  end
end
