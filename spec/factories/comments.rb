FactoryBot.define do
  factory :comment do
    user { nil }
    commentable { nil }
    content { "MyText" }
    selected_text { "MyText" }
    start_index { 1 }
    end_index { 1 }
    status { 1 }
  end
end
