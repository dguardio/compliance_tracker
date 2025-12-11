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
    setup_dashboard_data
  end

  private

  def setup_dashboard_data
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

    # Onboarding Progress
    @onboarding_progress = {
      org_structure: @organization.departments.exists? && @organization.teams.exists? && @organization.units.exists?,
      users_added: @organization.users.count > 1, # More than just the creator
      framework_imported: @organization.compliance_frameworks.exists?,
      policy_created: @organization.documents.where(category: 'policy').exists?,
      risk_assessed: @organization.risk_assessments.exists?
    }
    @onboarding_percent = @onboarding_progress.values.count(true) * 20

    @overdue_tasks = @compliance_controls.overdue.includes(:assignee, :compliance_requirement).order(due_date: :asc).limit(5)

    # Recent activity (placeholder for future implementation)
    # METRICS FOR JOYFUL DASHBOARD
    # 1. Compliance Score (Simple heuristic: 100 - penalties)
    # Penalties: High Risk Assessment (-10), Overdue Task (-5), Overdue Risk (-5)
    high_risk_penalty = (@stats[:high_risk_assessments] || 0) * 10
    overdue_task_penalty = (@stats[:overdue_tasks] || 0) * 5
    overdue_risk_penalty = (@stats[:overdue_risk_assessments] || 0) * 5
    raw_score = 100 - (high_risk_penalty + overdue_task_penalty + overdue_risk_penalty)
    @compliance_score = [raw_score, 0].max

    # 2. Streak (Days since last High Risk created)
    # If no high risk items ever, use organization creation date
    last_high_risk = @organization.risk_assessments.where('risk_score >= ?', 13).order(created_at: :desc).first
    streak_start_date = last_high_risk ? last_high_risk.created_at.to_date : @organization.created_at.to_date
    @streak = (Date.current - streak_start_date).to_i

    # 3. Recent Activity Feed
    # Fetch last 5 items from RiskAssessment and Document
    recent_risks = @risk_assessments.order(created_at: :desc).limit(5).map do |r|
      {
        user: r.created_by,
        action: "created risk assessment",
        item: r,
        item_name: r.name,
        time: r.created_at,
        type: 'risk'
      }
    end

    recent_docs = @organization.documents.includes(:uploaded_by).order(created_at: :desc).limit(5).map do |d|
      {
        user: d.uploaded_by,
        action: "uploaded document",
        item: d,
        item_name: d.title,
        time: d.created_at,
        type: 'document'
      }
    end

    @recent_activity = (recent_risks + recent_docs).sort_by { |a| a[:time] }.reverse.first(5)
  end

  def ensure_user_has_organization
    return if current_user.organization

    redirect_to new_organization_path, alert: 'You must be part of an organization to access the dashboard.'
  end
end
