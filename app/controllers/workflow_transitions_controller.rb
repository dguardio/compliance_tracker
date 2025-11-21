# frozen_string_literal: true

class WorkflowTransitionsController < ApplicationController
  before_action :set_workflow_template

  def create
    transition_params = params.require(:workflow_transition).permit(:from_id, :to_id, :condition, :source_anchor_type, :target_anchor_type)

    @from_step = @workflow_template.workflow_steps.find(transition_params[:from_id])
    @to_step = @workflow_template.workflow_steps.find(transition_params[:to_id])
    
    @transition = @from_step.transitions.new(
      next_step: @to_step, 
      condition: transition_params[:condition], 
      source_anchor_type: transition_params[:source_anchor_type],
      target_anchor_type: transition_params[:target_anchor_type]
    )

    if @transition.save
      render json: { status: 'success', transition_id: @transition.id }, status: :created
    else
      render json: { status: 'error', errors: @transition.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @transition = WorkflowTransition.find(params[:id])
    authorize @transition # Or some other authorization mechanism
    
    if @transition.destroy
      render json: { status: 'success' }, status: :ok
    else
      render json: { status: 'error', errors: 'Could not delete transition' }, status: :unprocessable_entity
    end
  end

  private

  def set_workflow_template
    @workflow_template = WorkflowTemplate.find(params[:workflow_template_id])
  end
end
