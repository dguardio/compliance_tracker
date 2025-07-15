class AddOrganizationIdToProviders < ActiveRecord::Migration[7.1]
  def change
    add_reference :providers, :organization, null: true, foreign_key: true
  end
end
