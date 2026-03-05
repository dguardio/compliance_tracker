class CreateVendorManagement < ActiveRecord::Migration[7.1]
  def change
    # Vendor Registry
    create_table :vendors do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :website
      t.integer :risk_tier, null: false, default: 2
      t.integer :status, null: false, default: 0
      t.text :description
      t.string :primary_contact_name
      t.string :primary_contact_email
      t.date :contract_start
      t.date :contract_end
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :vendors, [:organization_id, :risk_tier]
    add_index :vendors, [:organization_id, :name], unique: true

    # Vendor Assessments
    create_table :vendor_assessments do |t|
      t.references :vendor, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.references :assessed_by, foreign_key: { to_table: :users }, null: true
      t.integer :assessment_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.integer :risk_score
      t.date :assessment_date
      t.date :next_review_date
      t.text :notes
      t.jsonb :questionnaire_responses, default: {}

      t.timestamps
    end

    add_index :vendor_assessments, [:vendor_id, :assessment_date]
  end
end
