class CreateRegulationExtractions < ActiveRecord::Migration[7.1]
  def change
    create_table :regulation_extractions do |t|
      t.references :regulation, null: false, foreign_key: true
      t.references :custom_column, null: false, foreign_key: true
      t.text :extracted_value
      t.text :reasoning
      t.text :source_text
      t.float :confidence_score

      t.timestamps
    end
    
    add_index :regulation_extractions, [:regulation_id, :custom_column_id], unique: true, name: 'index_reg_extractions_on_reg_and_column'
  end
end
