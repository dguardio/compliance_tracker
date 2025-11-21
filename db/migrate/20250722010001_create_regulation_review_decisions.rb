# frozen_string_literal: true

class CreateRegulationReviewDecisions < ActiveRecord::Migration[7.1]
  def change
    create_table :regulation_review_decisions do |t|
      t.references :regulation_review, null: false, foreign_key: true
      t.references :workflow_step, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :decision, null: false
      t.text :notes

      t.timestamps
    end
  end
end
