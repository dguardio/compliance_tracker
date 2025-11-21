# frozen_string_literal: true

class WorkflowStep < ApplicationRecord
  belongs_to :workflow_template
  belongs_to :role

  has_many :transitions, class_name: 'WorkflowTransition', foreign_key: 'workflow_step_id', dependent: :destroy
  has_many :incoming_transitions, class_name: 'WorkflowTransition', foreign_key: 'next_step_id', dependent: :destroy

  validates :name, presence: true
  validates :role, presence: true
  validates :step_type, presence: true

  # You can add an enum for step_type if you have a fixed set of types
  # enum step_type: { review: 'review', decision: 'decision', acknowledgement: 'acknowledgement' }

  def decision_options=(options)
    if options.is_a?(String)
      if options == '[]'
        self[:decision_options] = []
      else
        self[:decision_options] = options.split(',').map(&:strip).reject(&:blank?)
      end
    else
      self[:decision_options] = options
    end
  end
end

