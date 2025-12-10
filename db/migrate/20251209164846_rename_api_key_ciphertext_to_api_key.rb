class RenameApiKeyCiphertextToApiKey < ActiveRecord::Migration[7.1]
  def change
    rename_column :regulatory_data_sources, :api_key_ciphertext, :api_key
  end
end
