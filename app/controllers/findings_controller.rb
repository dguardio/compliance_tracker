class FindingsController < ApplicationController
  before_action -> { require_feature!(:findings_remediation) }
  before_action :set_organization
  before_action :set_finding, only: %i[show edit update destroy close reopen]
  before_action :authorize_finding

  def index
    @findings = @organization.findings.includes(:compliance_control, :compliance_framework, :assigned_to, :created_by)

    # Filters
    @findings = @findings.where(status: params[:status]) if params[:status].present?
    @findings = @findings.where(severity: params[:severity]) if params[:severity].present?
    @findings = @findings.where(source: params[:source]) if params[:source].present?
    @findings = @findings.where(root_cause: params[:root_cause]) if params[:root_cause].present?
    @findings = @findings.where(assigned_to_id: params[:assigned_to]) if params[:assigned_to].present?

    @findings = @findings.order(created_at: :desc)

    # Dashboard stats
    @stats = {
      total: @organization.findings.count,
      open: @organization.findings.status_open.count,
      in_progress: @organization.findings.status_in_progress.count,
      overdue: @organization.findings.overdue.count,
      critical: @organization.findings.severity_critical.count,
      high: @organization.findings.severity_high.count
    }
  end

  def show
    @corrective_actions = @finding.corrective_actions.includes(:assigned_to).order(created_at: :desc)
    @new_corrective_action = @finding.corrective_actions.build
  end

  def new
    @finding = @organization.findings.build
    @finding.created_by = current_user
  end

  def create
    @finding = @organization.findings.build(finding_params)
    @finding.created_by = current_user

    if @finding.save
      redirect_to organization_finding_path(@organization, @finding),
                  notice: 'Finding was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @finding.update(finding_params)
      redirect_to organization_finding_path(@organization, @finding),
                  notice: 'Finding was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @finding.destroy
    redirect_to organization_findings_path(@organization),
                notice: 'Finding was successfully deleted.'
  end

  def close
    @finding.resolve!(params[:resolution_notes])
    redirect_to organization_finding_path(@organization, @finding),
                notice: 'Finding has been closed.'
  end

  def reopen
    @finding.update!(status: :open, resolved_at: nil, resolution_notes: nil)
    redirect_to organization_finding_path(@organization, @finding),
                notice: 'Finding has been reopened.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_finding
    @finding = @organization.findings.find(params[:id])
  end

  def finding_params
    params.require(:finding).permit(
      :title, :description, :source, :severity, :status, :root_cause,
      :compliance_control_id, :compliance_requirement_id, :compliance_framework_id,
      :document_id, :assigned_to_id, :sla_deadline, :resolution_notes
    )
  end

  def authorize_finding
    case action_name
    when 'index'
      authorize Finding.new(organization: @organization), :index?
    when 'show'
      authorize @finding, :show?
    when 'new', 'create'
      authorize Finding.new(organization: @organization), :create?
    when 'edit', 'update', 'close', 'reopen'
      authorize @finding, :update?
    when 'destroy'
      authorize @finding, :destroy?
    end
  end
end
