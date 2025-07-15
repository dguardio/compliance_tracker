class AddProviderTypeToProviders < ActiveRecord::Migration[7.1]
  def change
    add_column :providers, :provider_type, :integer
  end
end
