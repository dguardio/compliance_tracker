class CreateComplianceControls < ActiveRecord::Migration[7.1]
  def change
    create_table :compliance_controls do |t|
      t.string :name
      t.integer :control_type
      t.text :description
      t.integer :effectiveness
      t.integer :status
      t.references :compliance_requirement, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.jsonb :settings

      t.timestamps
    end
  end
end
