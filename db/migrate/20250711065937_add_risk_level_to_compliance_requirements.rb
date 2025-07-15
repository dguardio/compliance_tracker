class AddRiskLevelToComplianceRequirements < ActiveRecord::Migration[7.1]
  def change
    add_column :compliance_requirements, :risk_level, :integer
  end
end
