class CreateEvidenceRequestDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :evidence_request_documents do |t|
      t.references :evidence_request, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true

      t.timestamps
    end
  end
end
