class CreateComplianceFrameworks < ActiveRecord::Migration[7.1]
  def change
    create_table :compliance_frameworks do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :version
      t.integer :status
      t.references :organization, null: false, foreign_key: true
      t.jsonb :settings

      t.timestamps
    end
  end
end
