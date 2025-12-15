module Admin
  class AgentTracesController < ApplicationController
    before_action :authenticate_user!
    before_action :ensure_admin_access!

    def index
      @traces = Ai::AgentTrace.roots.recent.page(params[:page]).per(20)
    end

    def show
      @trace = Ai::AgentTrace.find(params[:id])
    end

    private

    def ensure_admin_access!
      # Assuming simple role check or Pundit. 
      # Adapting to project style:
      unless current_user&.super_admin?
        redirect_to root_path, alert: "Access denied."
      end
    end
  end
end
