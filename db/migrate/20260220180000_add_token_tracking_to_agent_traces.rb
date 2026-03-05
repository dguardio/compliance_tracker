class AddTokenTrackingToAgentTraces < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_agent_traces, :input_tokens,      :integer
    add_column :ai_agent_traces, :output_tokens,      :integer
    add_column :ai_agent_traces, :model_used,         :string
    add_column :ai_agent_traces, :estimated_cost_usd, :decimal, precision: 12, scale: 8

    add_index :ai_agent_traces, :agent_name
    add_index :ai_agent_traces, :created_at
  end
end
