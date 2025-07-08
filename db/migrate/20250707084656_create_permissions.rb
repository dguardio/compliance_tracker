class CreatePermissions < ActiveRecord::Migration[7.1]
  def change
    create_table :permissions do |t|
      t.string :name
      t.string :resource_type
      t.integer :resource_id
      t.string :action
      t.jsonb :conditions
      t.references :organization, null: false, foreign_key: true

      # Polymorphic grantee (User or Role)
      t.string :grantee_type, null: false
      t.bigint :grantee_id, null: false

      t.timestamps
    end

    add_index :permissions, [:grantee_type, :grantee_id]
    add_index :permissions, [:resource_type, :resource_id]
  end
end
