class CreateComplianceRequirements < ActiveRecord::Migration[7.1]
  def change
    create_table :compliance_requirements do |t|
      t.string :name
      t.string :code
      t.text :description
      t.integer :requirement_type
      t.integer :priority
      t.integer :status
      t.references :compliance_framework, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.jsonb :settings

      t.timestamps
    end
  end
end
