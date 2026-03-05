class AddAiCommentaryToMaturitySnapshots < ActiveRecord::Migration[7.1]
  def change
    add_column :maturity_snapshots, :ai_commentary, :text
  end
end
