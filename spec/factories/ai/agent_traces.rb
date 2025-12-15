FactoryBot.define do
  factory :ai_agent_trace, class: 'Ai::AgentTrace' do
    run_id { "MyString" }
    agent_name { "MyString" }
    action { "MyString" }
    input { "" }
    output { "MyText" }
    metadata { "" }
    status { "MyString" }
    parent_trace_id { "" }
    duration { 1.5 }
  end
end
