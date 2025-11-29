class RenameVersionToRevisionInRegulations < ActiveRecord::Migration[7.1]
  def change
    rename_column :regulations, :version, :revision
  end
end
