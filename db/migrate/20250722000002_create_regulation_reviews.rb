# frozen_string_literal: true

class CreateRegulationReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :regulation_reviews do |t|
      t.references :organization_regulation, null: false, foreign_key: true, index: { unique: true }
      t.references :workflow_template, null: false, foreign_key: true
      t.string :workflow_state, null: false
      t.string :status, null: false, default: 'in_progress'
      t.references :assignee, foreign_key: { to_table: :users }
      t.datetime :completed_at
      t.text :decision_notes

      t.timestamps
    end

    add_index :regulation_reviews, :workflow_state
    add_index :regulation_reviews, :status
  end
end
