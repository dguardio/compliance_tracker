class CreateFrameworkMappings < ActiveRecord::Migration[7.1]
  def change
    create_table :framework_mappings do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :source_requirement, null: false, foreign_key: { to_table: :compliance_requirements }
      t.references :target_requirement, null: false, foreign_key: { to_table: :compliance_requirements }
      t.integer :mapping_type, null: false, default: 0
      t.decimal :confidence, precision: 5, scale: 2
      t.boolean :ai_generated, default: false
      t.text :rationale

      t.timestamps
    end

    add_index :framework_mappings, [:source_requirement_id, :target_requirement_id],
              name: 'idx_framework_mappings_src_tgt', unique: true
    add_index :framework_mappings, [:organization_id, :mapping_type],
              name: 'idx_framework_mappings_org_type'
  end
end
