class CreateTestSamples < ActiveRecord::Migration[7.1]
  def change
    create_table :test_samples do |t|
      t.references :test_execution, null: false, foreign_key: true
      t.string :sample_identifier, null: false
      t.integer :result, default: 0, null: false
      t.text :notes
      t.text :evidence_notes
      t.datetime :tested_at

      t.timestamps
    end
  end
end
