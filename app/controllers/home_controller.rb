class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    return unless user_signed_in?

    if current_user.organization
      redirect_to dashboard_path
    else
      redirect_to organizations_path
    end

    # If not signed in, show the landing page
  end
end
