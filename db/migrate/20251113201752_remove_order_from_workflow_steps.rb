class RemoveOrderFromWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    remove_column :workflow_steps, :order, :integer
  end
end
