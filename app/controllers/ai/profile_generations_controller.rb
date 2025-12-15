# frozen_string_literal: true

module Ai
  class ProfileGenerationsController < ApplicationController
    before_action :authenticate_user!
    
    def create
      organization = Organization.find(params[:organization_id])
      authorize organization, :update?

      # Simulate network delay for "AI thinking" effect
      sleep 1.5

      profile = Ai::OrganizationProfileGenerator.new(organization).generate

      render json: profile
    end
  end
end
