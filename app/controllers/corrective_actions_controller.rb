class CorrectiveActionsController < ApplicationController
  before_action -> { require_feature!(:findings_remediation) }
  before_action :set_organization
  before_action :set_finding
  before_action :set_corrective_action, only: %i[update complete]
  before_action :authorize_corrective_action

  def create
    @corrective_action = @finding.corrective_actions.build(corrective_action_params)
    @corrective_action.created_by = current_user

    if @corrective_action.save
      redirect_to organization_finding_path(@organization, @finding),
                  notice: 'Corrective action was successfully created.'
    else
      @corrective_actions = @finding.corrective_actions.includes(:assigned_to).order(created_at: :desc)
      @new_corrective_action = @corrective_action
      render 'findings/show', status: :unprocessable_entity
    end
  end

  def update
    if @corrective_action.update(corrective_action_params)
      redirect_to organization_finding_path(@organization, @finding),
                  notice: 'Corrective action was successfully updated.'
    else
      redirect_to organization_finding_path(@organization, @finding),
                  alert: 'Failed to update corrective action.'
    end
  end

  def complete
    @corrective_action.complete!(params[:completion_notes])
    redirect_to organization_finding_path(@organization, @finding),
                notice: 'Corrective action marked as complete.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_finding
    @finding = @organization.findings.find(params[:finding_id])
  end

  def set_corrective_action
    @corrective_action = @finding.corrective_actions.find(params[:id])
  end

  def corrective_action_params
    params.require(:corrective_action).permit(
      :title, :description, :action_type, :priority, :status,
      :assigned_to_id, :due_date, :completion_notes
    )
  end

  def authorize_corrective_action
    case action_name
    when 'create'
      authorize CorrectiveAction.new(finding: @finding), :create?
    when 'update', 'complete'
      authorize @corrective_action, :update?
    end
  end
end
