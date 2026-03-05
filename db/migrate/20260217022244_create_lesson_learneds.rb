class CreateLessonLearneds < ActiveRecord::Migration[7.1]
  def change
    create_table :lesson_learneds do |t|
      t.references :incident, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.text :recommendations
      t.integer :category, default: 0, null: false
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
