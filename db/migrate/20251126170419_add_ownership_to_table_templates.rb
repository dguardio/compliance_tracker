class AddOwnershipToTableTemplates < ActiveRecord::Migration[7.1]
  def change
    add_reference :table_templates, :user, null: true, foreign_key: true
    add_reference :table_templates, :organization, null: true, foreign_key: true
  end
end
