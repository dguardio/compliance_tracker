require "rails_helper"

RSpec.describe Admin::RegulationsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/admin/regulations").to route_to("admin/regulations#index")
    end

    it "routes to #new" do
      expect(get: "/admin/regulations/new").to route_to("admin/regulations#new")
    end

    it "routes to #show" do
      expect(get: "/admin/regulations/1").to route_to("admin/regulations#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/admin/regulations/1/edit").to route_to("admin/regulations#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/admin/regulations").to route_to("admin/regulations#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/admin/regulations/1").to route_to("admin/regulations#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/admin/regulations/1").to route_to("admin/regulations#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/admin/regulations/1").to route_to("admin/regulations#destroy", id: "1")
    end
  end
end
