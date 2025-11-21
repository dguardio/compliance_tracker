# frozen_string_literal: true

class AddDecisionOptionsToWorkflowSteps < ActiveRecord::Migration[7.1]
  def change
    add_column :workflow_steps, :decision_options, :jsonb, default: []
  end
end
