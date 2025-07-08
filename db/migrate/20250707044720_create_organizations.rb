class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :slug
      t.string :domain
      t.jsonb :settings
      t.integer :status

      t.timestamps
    end
  end
end
