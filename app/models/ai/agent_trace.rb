class Ai::AgentTrace < ApplicationRecord
  self.table_name = 'ai_agent_traces'

  belongs_to :parent, class_name: 'Ai::AgentTrace', foreign_key: :parent_trace_id, optional: true
  has_many :children, class_name: 'Ai::AgentTrace', foreign_key: :parent_trace_id, dependent: :destroy

  validates :run_id, :agent_name, :status, presence: true

  enum status: { pending: 'pending', success: 'success', error: 'error' }

  scope :roots, -> { where(parent_trace_id: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def self.start_trace(run_id:, agent_name:, action:, input:, parent_id: nil)
    create!(
      run_id: run_id,
      agent_name: agent_name,
      action: action,
      input: input,
      parent_trace_id: parent_id,
      status: :pending,
      started_at: Time.current
    )
  end

  def complete!(output:, metadata: {})
    update!(
      output: output,
      metadata: metadata,
      status: :success,
      duration: Time.current - (created_at || Time.current)
    )
  end

  def fail!(error_message:, metadata: {})
    update!(
      output: error_message,
      metadata: metadata.merge(error: error_message),
      status: :error,
      duration: Time.current - (created_at || Time.current)
    )
  end
end
