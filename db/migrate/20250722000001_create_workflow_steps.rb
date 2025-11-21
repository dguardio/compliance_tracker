# frozen_string_literal: true

class CreateWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_steps do |t|
      t.string :name, null: false
      t.references :workflow_template, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.string :step_type, null: false
      t.integer :order, null: false
      t.text :description
      t.jsonb :settings, default: {}

      t.timestamps
    end

    add_index :workflow_steps, [:workflow_template_id, :order], unique: true
  end
end
