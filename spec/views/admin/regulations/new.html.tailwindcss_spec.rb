require 'rails_helper'

RSpec.describe "admin/regulations/new", type: :view do
  before(:each) do
    assign(:regulation, Regulation.new(
      title: "MyString",
      agency: "MyString",
      jurisdiction: "MyString",
      reg_type: "MyString",
      version: 1,
      status: "MyString",
      full_text: { "content": "MyText" },
      files: "",
      metadata: "",
      previous_version: nil
    ))
  end

  it "renders new regulation form" do
    render

    assert_select "form[action=?][method=?]", admin_regulations_path, "post" do

      assert_select "input[name=?]", "regulation[title]"

      assert_select "input[name=?]", "regulation[agency]"

      assert_select "input[name=?]", "regulation[jurisdiction]"

      assert_select "select[name=?]", "regulation[reg_type]"

      assert_select "input[name=?]", "regulation[version]"

      assert_select "select[name=?]", "regulation[status]"

      assert_select "textarea[name=?]", "regulation[full_text]"

      assert_select "textarea[name=?]", "regulation[files]"

      assert_select "textarea[name=?]", "regulation[metadata]"

      assert_select "input[name=?]", "regulation[previous_version_id]"
    end
  end
end
