class AddStandardRequirementToComplianceRequirements < ActiveRecord::Migration[7.1]
  def change
    add_reference :compliance_requirements, :standard_requirement, null: false, foreign_key: true
  end
end
