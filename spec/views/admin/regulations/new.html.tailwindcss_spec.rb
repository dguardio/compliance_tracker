require 'rails_helper'

RSpec.describe "admin/regulations/new", type: :view do
  before(:each) do
    assign(:admin_regulation, Admin::Regulation.new(
      title: "MyString",
      agency: "MyString",
      jurisdiction: "MyString",
      reg_type: "MyString",
      version: 1,
      status: "MyString",
      full_text: "",
      files: "",
      metadata: "",
      external_id: "MyString",
      previous_version_id: 1
    ))
  end

  it "renders new admin_regulation form" do
    render

    assert_select "form[action=?][method=?]", admin_regulations_path, "post" do

      assert_select "input[name=?]", "admin_regulation[title]"

      assert_select "input[name=?]", "admin_regulation[agency]"

      assert_select "input[name=?]", "admin_regulation[jurisdiction]"

      assert_select "input[name=?]", "admin_regulation[reg_type]"

      assert_select "input[name=?]", "admin_regulation[version]"

      assert_select "input[name=?]", "admin_regulation[status]"

      assert_select "input[name=?]", "admin_regulation[full_text]"

      assert_select "input[name=?]", "admin_regulation[files]"

      assert_select "input[name=?]", "admin_regulation[metadata]"

      assert_select "input[name=?]", "admin_regulation[external_id]"

      assert_select "input[name=?]", "admin_regulation[previous_version_id]"
    end
  end
end
