class WorkflowTransition < ApplicationRecord
  belongs_to :workflow_step, class_name: 'WorkflowStep'
  belongs_to :next_step, class_name: 'WorkflowStep'
end

