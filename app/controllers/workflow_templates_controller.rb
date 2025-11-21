# frozen_string_literal: true

class WorkflowTemplatesController < ApplicationController
  before_action :set_organization
  before_action :set_workflow_template, only: %i[show edit update destroy]

  def index
    @workflow_templates = @organization.workflow_templates.order(:name)
  end

  def show
    # Eager load steps, roles, and transitions to prevent N+1 queries
    @workflow_steps = @workflow_template.workflow_steps.includes(:role, :transitions)
    @new_workflow_step = @workflow_template.workflow_steps.new
    
    # Prepare transitions for the frontend
    @transitions_json = @workflow_steps.flat_map(&:transitions).map do |t|
      {
        id: t.id,
        source: "step-#{t.workflow_step_id}",
        target: "step-#{t.next_step_id}",
        label: t.condition,
        source_anchor_type: t.source_anchor_type,
        target_anchor_type: t.target_anchor_type
      }
    end.to_json
  end

  def new
    @workflow_template = @organization.workflow_templates.new
  end

  def create
    @workflow_template = @organization.workflow_templates.new(workflow_template_params)
    if @workflow_template.save
      redirect_to organization_workflow_template_path(@organization, @workflow_template), notice: 'Workflow template was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @workflow_template.update(workflow_template_params)
      redirect_to organization_workflow_template_path(@organization, @workflow_template), notice: 'Workflow template was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @workflow_template.destroy
    redirect_to organization_workflow_templates_path(@organization), notice: 'Workflow template was successfully destroyed.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
    set_current_tenant
  end

  def set_workflow_template
    @workflow_template = @organization.workflow_templates.find(params[:id])
  end

  def workflow_template_params
    params.require(:workflow_template).permit(:name, :description, :is_default)
  end
end
