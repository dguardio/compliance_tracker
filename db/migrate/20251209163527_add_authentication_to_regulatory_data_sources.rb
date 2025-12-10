class AddAuthenticationToRegulatoryDataSources < ActiveRecord::Migration[7.1]
  def change
    add_column :regulatory_data_sources, :api_key_ciphertext, :text
    add_column :regulatory_data_sources, :api_key_param, :string
  end
end
