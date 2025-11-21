class AddAnchorTypesToWorkflowTransitions < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_transitions, :source_anchor_type, :string
    add_column :workflow_transitions, :target_anchor_type, :string
  end
end
