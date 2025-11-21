# frozen_string_literal: true

class AddProviderToRegulatoryDataSources < ActiveRecord::Migration[7.1]
  def change
    add_reference :regulatory_data_sources, :provider, null: false, foreign_key: true
  end
end
