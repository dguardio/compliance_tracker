class CreateQuestionnaireUploads < ActiveRecord::Migration[7.1]
  def change
    create_table :questionnaire_uploads do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :uploaded_by, foreign_key: { to_table: :users }, null: true
      t.string :filename, null: false
      t.integer :status, null: false, default: 0
      t.integer :response_count, default: 0

      t.timestamps
    end

    create_table :questionnaire_answers do |t|
      t.references :questionnaire_upload, null: false, foreign_key: true
      t.text :question_text, null: false
      t.text :ai_answer
      t.text :approved_answer
      t.decimal :confidence, precision: 5, scale: 2
      t.references :source_policy, foreign_key: { to_table: :policies }, null: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :questionnaire_answers, [:questionnaire_upload_id, :status]
  end
end
