class AddSectorsAndJurisdictionsToRegulatoryDataSources < ActiveRecord::Migration[7.1]
  def change
    add_column :regulatory_data_sources, :sectors, :jsonb, default: []
    add_column :regulatory_data_sources, :jurisdictions, :jsonb, default: []
  end
end
