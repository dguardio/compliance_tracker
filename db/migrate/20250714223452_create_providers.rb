class CreateProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :providers do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :website
      t.string :jurisdiction, null: false
      t.string :state
      t.string :country, null: false
      t.jsonb :contact_info, default: {}
      t.jsonb :settings, default: {}
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :providers, :code, unique: true
    add_index :providers, :name
    add_index :providers, :jurisdiction
    add_index :providers, :country
    add_index :providers, :status
    add_index :providers, :settings, using: :gin
  end
end
