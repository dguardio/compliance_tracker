class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :title, null: false
      t.text :description
      t.string :category
      t.integer :status, default: 0
      t.references :organization, null: false, foreign_key: true
      t.references :compliance_framework, null: true, foreign_key: true
      t.references :compliance_requirement, null: true, foreign_key: true
      t.references :compliance_control, null: true, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.datetime :expires_at
      t.integer :version, default: 1
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :documents, :category
    add_index :documents, :status
    add_index :documents, :settings, using: :gin
  end
end
