class CreateWorkflowTransitions < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_transitions do |t|
      t.references :workflow_step, null: false, foreign_key: { to_table: :workflow_steps }
      t.references :next_step, null: false, foreign_key: { to_table: :workflow_steps }
      t.string :condition

      t.timestamps
    end
  end
end

