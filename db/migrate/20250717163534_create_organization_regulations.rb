class CreateOrganizationRegulations < ActiveRecord::Migration[7.1]
  def change
    create_table :organization_regulations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :regulation, null: false, foreign_key: true
      t.references :compliance_framework, null: true, foreign_key: true
      t.integer :priority, default: 0
      t.string :status, default: 'pending'
      t.datetime :assigned_at
      t.references :assigned_by, null: true, foreign_key: { to_table: :users }
      t.text :notes

      t.timestamps
    end

    # Add indexes for better query performance
    add_index :organization_regulations, [:organization_id, :regulation_id], unique: true, name: 'index_org_regs_on_org_and_reg_unique'
    add_index :organization_regulations, [:organization_id, :status]
    add_index :organization_regulations, [:organization_id, :priority]
    add_index :organization_regulations, [:regulation_id, :status]
    # Note: Rails automatically creates an index for compliance_framework_id foreign key
  end
end
