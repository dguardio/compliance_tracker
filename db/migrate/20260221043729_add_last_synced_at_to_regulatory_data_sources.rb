class AddLastSyncedAtToRegulatoryDataSources < ActiveRecord::Migration[7.1]
  def change
    add_column :regulatory_data_sources, :last_synced_at, :datetime
  end
end
