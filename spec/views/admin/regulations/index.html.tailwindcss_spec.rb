require 'rails_helper'

RSpec.describe "admin/regulations/index", type: :view do
  before(:each) do
    assign(:admin_regulations, [
      Admin::Regulation.create!(
        title: "Title",
        agency: "Agency",
        jurisdiction: "Jurisdiction",
        reg_type: "Reg Type",
        version: 2,
        status: "Status",
        full_text: "",
        files: "",
        metadata: "",
        external_id: "External",
        previous_version_id: 3
      ),
      Admin::Regulation.create!(
        title: "Title",
        agency: "Agency",
        jurisdiction: "Jurisdiction",
        reg_type: "Reg Type",
        version: 2,
        status: "Status",
        full_text: "",
        files: "",
        metadata: "",
        external_id: "External",
        previous_version_id: 3
      )
    ])
  end

  it "renders a list of admin/regulations" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Agency".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Jurisdiction".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Reg Type".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Status".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("External".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
