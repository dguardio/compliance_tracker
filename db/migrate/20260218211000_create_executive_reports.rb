class CreateExecutiveReports < ActiveRecord::Migration[7.1]
  def change
    create_table :executive_reports do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :report_type, null: false, default: 0
      t.date :period_start
      t.date :period_end
      t.text :narrative
      t.jsonb :metrics, default: {}
      t.integer :status, null: false, default: 0
      t.references :generated_by, foreign_key: { to_table: :users }, null: true

      t.timestamps
    end

    add_index :executive_reports, [:organization_id, :report_type]
  end
end
