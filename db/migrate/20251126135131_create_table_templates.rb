class CreateTableTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :table_templates do |t|
      t.string :name
      t.text :description
      t.string :category
      t.jsonb :columns

      t.timestamps
    end
  end
end
