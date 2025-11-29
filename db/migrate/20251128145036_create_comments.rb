class CreateComments < ActiveRecord::Migration[7.1]
  def change
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :commentable, polymorphic: true, null: false
      t.text :content
      t.text :selected_text
      t.integer :start_index
      t.integer :end_index
      t.integer :status

      t.timestamps
    end
  end
end
