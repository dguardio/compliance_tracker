# frozen_string_literal: true

class WorkflowStepsController < ApplicationController
  before_action :set_organization_and_template
  before_action :set_workflow_step, only: %i[edit update destroy condition_form update_position]
  before_action :prepare_decision_options, only: %i[create update]

  def create
    @workflow_step = @workflow_template.workflow_steps.new(workflow_step_params)
    respond_to do |format|
      if @workflow_step.save
        format.html { redirect_to organization_workflow_template_path(@organization, @workflow_template), notice: 'Workflow step was successfully added.' }
        format.turbo_stream
      else
        format.html do
          # To re-render the show page correctly, we need the other instance variables
          @workflow_steps = @workflow_template.workflow_steps.includes(:role)
          @new_workflow_step = @workflow_step # Pass the failed object back to the form
          flash.now[:alert] = "Failed to add workflow step: #{@workflow_step.errors.full_messages.join(', ')}"
          render 'workflow_templates/show', status: :unprocessable_entity
        end
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if @workflow_step.update(workflow_step_params)
        format.html { redirect_to organization_workflow_template_path(@organization, @workflow_template), notice: 'Workflow step was successfully updated.' }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity, layout: false }
        format.turbo_stream { render :edit, status: :unprocessable_entity, layout: false }
      end
    end
  end

  def destroy
    @workflow_step.destroy
    redirect_to organization_workflow_template_path(@organization, @workflow_template), notice: 'Workflow step was successfully destroyed.'
  end

  def condition_form
    render layout: false
  end

  def update_position
    if @workflow_step.update(position_x: params[:position_x], position_y: params[:position_y])
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def set_workflow_step
    @workflow_step = @workflow_template.workflow_steps.find(params[:id])
  end

  def set_organization_and_template
    @organization = Organization.find(params[:organization_id])
    @workflow_template = @organization.workflow_templates.find(params[:workflow_template_id])
    # Set tenant for this request
    set_current_tenant
  end

  def prepare_decision_options
    options = params.dig(:workflow_step, :decision_options)
    if options.is_a?(String)
      params[:workflow_step][:decision_options] = options.split(',').map(&:strip).reject(&:blank?)
    end
  end

  def workflow_step_params
    params.require(:workflow_step).permit(:name, :role_id, :step_type, :order, :description, decision_options: [])
  end
end
