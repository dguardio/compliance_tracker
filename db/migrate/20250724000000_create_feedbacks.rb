# frozen_string_literal: true

class CreateFeedbacks < ActiveRecord::Migration[7.1]
  def change
    create_table :feedbacks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :feedbackable, polymorphic: true, null: false
      t.text :content, null: false
      t.string :status, null: false, default: 'open'

      t.timestamps
    end
  end
end
