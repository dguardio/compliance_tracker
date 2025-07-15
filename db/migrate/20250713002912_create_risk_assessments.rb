class CreateRiskAssessments < ActiveRecord::Migration[7.1]
  def change
    create_table :risk_assessments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :compliance_framework, null: false, foreign_key: true
      t.references :compliance_requirement, null: false, foreign_key: true
      t.references :compliance_control, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :likelihood
      t.integer :impact
      t.integer :risk_score
      t.integer :status
      t.date :assessment_date
      t.date :next_review_date
      t.text :mitigation_plan
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :assigned_to, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
