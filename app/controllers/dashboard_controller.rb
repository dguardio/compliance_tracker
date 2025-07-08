class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_user_has_organization, except: [:index]

  def index
    if user_signed_in?
      if current_user.organization
        redirect_to dashboard_path
      else
        redirect_to new_organization_path, notice: 'Please create or join an organization to continue.'
      end
    else
      redirect_to new_user_session_path
    end
  end

  def dashboard
    @organization = current_user.organization
    @departments = @organization.departments.includes(:teams, :units)
    @users = @organization.users.includes(:roles, :department, :team, :unit)
    
    @stats = {
      departments: @organization.department_count,
      teams: @organization.team_count,
      units: @organization.unit_count,
      users: @organization.user_count
    }
    
    # Recent activity (placeholder for future implementation)
    @recent_activity = []
  end

  private

  def ensure_user_has_organization
    unless current_user.organization
      redirect_to new_organization_path, alert: 'You must be part of an organization to access the dashboard.'
    end
  end
end
