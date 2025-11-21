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
    @compliance_frameworks = @organization.compliance_frameworks.includes(:compliance_requirements)
    @risk_assessments = @organization.risk_assessments.includes(:created_by, :assigned_to, :compliance_framework,
                                                                :compliance_requirement, :compliance_control)
    @compliance_controls = @organization.compliance_controls

    @stats = {
      departments: @organization.department_count,
      teams: @organization.team_count,
      units: @organization.unit_count,
      users: @organization.user_count,
      compliance_frameworks: @organization.compliance_frameworks.count,
      risk_assessments: @organization.risk_assessments.count,
      high_risk_assessments: @organization.risk_assessments.where('risk_score >= ?', 13).count,
      overdue_risk_assessments: @organization.risk_assessments.where('next_review_date < ?', Date.current).count,
      documents: @organization.documents.count,
      documents_needing_review: @organization.documents.where(status: 'review').count,
      documents_expiring_soon: @organization.documents.expiring_soon.count,
      
      # New Task-related stats
      total_tasks: @compliance_controls.count,
      tasks_by_status: @compliance_controls.group(:status).count,
      overdue_tasks: @compliance_controls.overdue.count,
      due_soon_tasks: @compliance_controls.due_soon.count
    }

    @overdue_tasks = @compliance_controls.overdue.includes(:assignee, :compliance_requirement).order(due_date: :asc).limit(5)

    # Recent activity (placeholder for future implementation)
    @recent_activity = []
  end

  private

  def ensure_user_has_organization
    return if current_user.organization

    redirect_to new_organization_path, alert: 'You must be part of an organization to access the dashboard.'
  end
end
