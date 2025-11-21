class AddPositionToWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_steps, :position_x, :integer
    add_column :workflow_steps, :position_y, :integer
  end
end
