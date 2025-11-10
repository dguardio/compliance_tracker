require 'rails_helper'

RSpec.describe "admin/regulations/show", type: :view do
  before(:each) do
    assign(:regulation, Regulation.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Agency/)
    expect(rendered).to match(/Jurisdiction/)
    expect(rendered).to match(/Reg Type/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Status/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
