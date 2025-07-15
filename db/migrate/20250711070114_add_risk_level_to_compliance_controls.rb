class AddRiskLevelToComplianceControls < ActiveRecord::Migration[7.1]
  def change
    add_column :compliance_controls, :risk_level, :integer
  end
end
