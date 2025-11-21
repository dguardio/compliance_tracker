# frozen_string_literal: true

class CreateRegulatoryDataSources < ActiveRecord::Migration[7.1]
  def change
    create_table :regulatory_data_sources do |t|
      t.string :name, null: false
      t.text :description
      t.string :source_type, null: false
      t.string :url, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :regulatory_data_sources, :name, unique: true
    add_index :regulatory_data_sources, :source_type
    add_index :regulatory_data_sources, :status
  end
end
