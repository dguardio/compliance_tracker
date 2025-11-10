require 'rails_helper'

RSpec.describe "admin/regulations/index", type: :view do
  before(:each) do
    assign(:regulations, [
      Regulation.create!(
        title: "Title",
        agency: "Agency",
        jurisdiction: "Jurisdiction",
        reg_type: "Reg Type",
        version: 2,
        status: "Status",
        full_text: { "content": "MyText" },
        files: "",
        metadata: "",
        previous_version: nil
      ),
      Regulation.create!(
        title: "Title",
        agency: "Agency",
        jurisdiction: "Jurisdiction",
        reg_type: "Reg Type",
        version: 2,
        status: "Status",
        full_text: { "content": "MyText" },
        files: "",
        metadata: "",
        previous_version: nil
      )
    ])
  end

  it "renders a list of regulations" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Agency".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Jurisdiction".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Reg Type".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Status".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
