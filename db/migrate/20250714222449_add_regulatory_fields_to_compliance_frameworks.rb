class AddRegulatoryFieldsToComplianceFrameworks < ActiveRecord::Migration[7.1]
  def change
    add_column :compliance_frameworks, :provider, :string
    add_column :compliance_frameworks, :issuance_type, :string
    add_column :compliance_frameworks, :publication_date, :date
    add_column :compliance_frameworks, :provider_url, :string
    add_column :compliance_frameworks, :enforcement_date, :date
    add_column :compliance_frameworks, :potentially_impacted_departments, :text
  end
end
