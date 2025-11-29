class CreateCustomColumns < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_columns do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :prompt, null: false
      t.string :column_type, default: 'text'
      t.boolean :is_template, default: false

      t.timestamps
    end
    
    add_index :custom_columns, [:user_id, :name], unique: true
  end
end
