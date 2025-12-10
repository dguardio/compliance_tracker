module Users
  class ImportsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_organization
    before_action :authorize_import

    def new
    end

    def create
      if params[:file].nil?
        flash.now[:alert] = "Please select a file to upload."
        render :new, status: :unprocessable_entity
        return
      end

      importer = UserImporter.new(params[:file], @organization)
      
      if importer.import
        redirect_to organization_users_path(@organization), notice: "Users imported successfully."
      else
        @errors = importer.errors
        flash.now[:alert] = "There were errors importing users."
        render :new, status: :unprocessable_entity
      end
    end

    private

    def set_organization
      @organization = Organization.find(params[:organization_id])
    end

    def authorize_import
      authorize @organization, :update? # Assuming update permission allows importing users
    end
  end
end
