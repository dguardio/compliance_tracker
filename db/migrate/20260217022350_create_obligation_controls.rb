class CreateObligationControls < ActiveRecord::Migration[7.1]
  def change
    create_table :obligation_controls do |t|
      t.references :obligation, null: false, foreign_key: true
      t.references :compliance_control, null: false, foreign_key: true

      t.timestamps
    end

    add_index :obligation_controls, [:obligation_id, :compliance_control_id], unique: true, name: 'idx_obligation_controls_unique'
  end
end
