# frozen_string_literal: true

class RegulationReview < ApplicationRecord
  include Workflow

  belongs_to :organization_regulation
  belongs_to :workflow_template
  belongs_to :assignee, class_name: 'User', optional: true

  validates :workflow_template, presence: true
  validates :workflow_state, presence: true
  validates :status, presence: true

  enum status: { review_in_progress: 'in_progress', review_completed: 'completed', review_rejected: 'rejected' }, _prefix: :review

  after_initialize :load_workflow_spec


  private

  def load_workflow_spec
    return unless workflow_template

    spec = self
    template_steps = workflow_template.workflow_steps.includes(:transitions)

    # Find the initial state (a step with no incoming transitions)
    step_ids_with_incoming_transitions = WorkflowTransition.where(next_step_id: template_steps.pluck(:id)).pluck(:next_step_id)
    initial_step = template_steps.find { |step| !step_ids_with_incoming_transitions.include?(step.id) }
    
    return unless initial_step

    spec.workflow_spec do
      on_transition { notify_assignees_of_new_step }

      # Define all steps as states first
      template_steps.each do |step|
        state step.name.parameterize.underscore.to_sym, name: step.name.humanize
      end

      # Define terminal states
      state :completed, name: 'Completed'
      state :rejected, name: 'Rejected'

      # Create events based on transitions
      template_steps.each do |step|
        current_state_sym = step.name.parameterize.underscore.to_sym
        
        state current_state_sym do
          if step.transitions.any?
            step.transitions.each do |transition|
              event_name = transition.condition.parameterize.underscore.to_sym
              next_state_sym = transition.next_step.name.parameterize.underscore.to_sym
              event event_name, transitions_to: next_state_sym
            end
          else
            # If a step has no outgoing transitions, it's a terminal step in the main flow
            event :complete, transitions_to: :completed
          end
          
          # Add a universal reject event to all non-terminal states
          event :reject, transitions_to: :rejected unless state == :rejected
        end
      end
    end
    
    # Set initial state if not already set
    self.workflow_state ||= initial_step.name.parameterize.underscore.to_sym
  end

  def notify_assignees_of_new_step
    # Find the workflow step corresponding to the new state
    current_workflow_step = workflow_template.workflow_steps.find_by(name: workflow_state.humanize)
    
    if current_workflow_step && current_workflow_step.role
      # Find users with the assigned role in the organization
      assignees = organization_regulation.organization.users.with_role(current_workflow_step.role.name)
      
      assignees.each do |user|
        RegulationReviewNotifier.with(regulation_review: self, new_state: workflow_state.humanize).deliver_later(user)
      end
    else
      Rails.logger.warn "No role found for workflow state '#{workflow_state}' or no current_workflow_step for RegulationReview #{id}. No notification sent."
    end
  end
end
