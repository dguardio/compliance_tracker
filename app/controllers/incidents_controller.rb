class IncidentsController < ApplicationController
  before_action -> { require_feature!(:incident_management) }
  before_action :set_organization
  before_action :set_incident, only: %i[show edit update destroy resolve close]
  before_action :authorize_incident

  def index
    @incidents = @organization.incidents.includes(:reported_by, :assigned_to)
    @incidents = @incidents.where(status: params[:status]) if params[:status].present?
    @incidents = @incidents.where(severity: params[:severity]) if params[:severity].present?
    @incidents = @incidents.where(category: params[:category]) if params[:category].present?
    @incidents = @incidents.order(created_at: :desc)

    @stats = {
      total: @organization.incidents.count,
      active: @organization.incidents.active_incidents.count,
      critical: @organization.incidents.where(severity: :critical).count,
      high: @organization.incidents.where(severity: :high).count
    }
  end

  def show
    @lessons = @incident.lesson_learneds.includes(:created_by).recent
    @new_lesson = @incident.lesson_learneds.build
    @findings = Finding.where(organization: @organization, title: "Incident: #{@incident.title}") if defined?(Finding)
  end

  def new
    @incident = @organization.incidents.build
  end

  def create
    @incident = @organization.incidents.build(incident_params)
    @incident.reported_by = current_user

    if @incident.save
      redirect_to organization_incident_path(@organization, @incident),
                  notice: 'Incident was successfully reported.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @incident.update(incident_params)
      redirect_to organization_incident_path(@organization, @incident),
                  notice: 'Incident was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @incident.destroy
    redirect_to organization_incidents_path(@organization), notice: 'Incident deleted.'
  end

  def resolve
    @incident.resolve!(params[:root_cause])
    redirect_to organization_incident_path(@organization, @incident), notice: 'Incident resolved.'
  end

  def close
    @incident.close!
    redirect_to organization_incident_path(@organization, @incident), notice: 'Incident closed.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_incident
    @incident = @organization.incidents.find(params[:id])
  end

  def incident_params
    params.require(:incident).permit(
      :title, :description, :category, :severity, :status,
      :assigned_to_id, :occurred_at, :detected_at,
      :impact_description, :root_cause
    )
  end

  def authorize_incident
    case action_name
    when 'index'
      authorize Incident.new(organization: @organization), :index?
    when 'show'
      authorize @incident, :show?
    when 'new', 'create'
      authorize Incident.new(organization: @organization), :create?
    when 'edit', 'update', 'resolve', 'close'
      authorize @incident, :update?
    when 'destroy'
      authorize @incident, :destroy?
    end
  end
end
