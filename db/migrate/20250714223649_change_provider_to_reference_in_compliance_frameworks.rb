class ChangeProviderToReferenceInComplianceFrameworks < ActiveRecord::Migration[7.1]
  def change
    # Remove the old provider string column
    remove_column :compliance_frameworks, :provider, :string
    
    # Add the new provider_id foreign key (this automatically creates an index)
    add_reference :compliance_frameworks, :provider, null: true, foreign_key: true
  end
end
