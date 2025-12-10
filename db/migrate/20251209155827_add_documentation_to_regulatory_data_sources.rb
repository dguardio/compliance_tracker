class AddDocumentationToRegulatoryDataSources < ActiveRecord::Migration[7.1]
  def change
    add_column :regulatory_data_sources, :documentation_url, :string
    add_column :regulatory_data_sources, :documentation_content, :text
  end
end
