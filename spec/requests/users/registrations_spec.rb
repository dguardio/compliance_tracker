require 'rails_helper'

RSpec.describe "Users::Registrations", type: :request do
  describe "GET /new" do
    it "returns http success" do
      get "/users/registrations/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/users/registrations/create"
      expect(response).to have_http_status(:success)
    end
  end

end
