class AddRegulationToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_reference :documents, :regulation, foreign_key: true, null: true
    change_column_null :documents, :organization_id, true
  end
end
