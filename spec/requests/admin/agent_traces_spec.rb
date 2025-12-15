require 'rails_helper'

RSpec.describe "Admin::AgentTraces", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/agent_traces/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/agent_traces/show"
      expect(response).to have_http_status(:success)
    end
  end

end
