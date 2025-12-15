class CreateStandardRequirements < ActiveRecord::Migration[7.1]
  def change
    create_table :standard_requirements do |t|
      t.string :name
      t.text :description
      t.references :regulation, null: false, foreign_key: true
      t.string :category
      t.string :external_id
      t.column :embedding, 'vector(1536)'
      t.timestamps
    end
    add_index :standard_requirements, :embedding, using: :hnsw, opclass: :vector_l2_ops
  end
end
