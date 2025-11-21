# frozen_string_literal: true

class CreateWorkflowTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_templates do |t|
      t.string :name, null: false
      t.references :organization, null: false, foreign_key: true
      t.boolean :is_default, default: false, null: false
      t.text :description

      t.timestamps
    end

    add_index :workflow_templates, [:organization_id, :name], unique: true
  end
end
