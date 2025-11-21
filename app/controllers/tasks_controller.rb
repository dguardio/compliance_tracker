# frozen_string_literal: true

class TasksController < ApplicationController
  def index
    tasks = current_user.assigned_controls.includes(:compliance_requirement)

    case params[:filter]
    when 'overdue'
      tasks = tasks.overdue
      @filter_title = "Overdue Tasks"
    when 'due_soon'
      tasks = tasks.due_soon
      @filter_title = "Tasks Due Soon"
    end

    @tasks = tasks.group_by(&:status)
    @statuses = ComplianceControl.statuses.keys
  end

  def show
    @task = ComplianceControl.find(params[:id])
  end

  def update_status
    @task = ComplianceControl.find(params[:id])
    authorize @task, :update? # Reuse the update policy

    if @task.update(status: params[:status])
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
