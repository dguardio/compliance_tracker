class CreateAiAgentTraces < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_agent_traces do |t|
      t.string :run_id
      t.string :agent_name
      t.string :action
      t.jsonb :input
      t.text :output
      t.jsonb :metadata
      t.string :status
      t.bigint :parent_trace_id
      t.float :duration

      t.timestamps
    end
    add_index :ai_agent_traces, :run_id
  end
end
