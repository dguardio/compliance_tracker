# frozen_string_literal: true

class RegulationReviewsController < ApplicationController
  before_action :set_regulation_review, only: %i[show update]

  def index
    # Get the current user's roles within their organization
    user_roles = current_user.roles.where(resource: current_user.organization).pluck(:name)
    
    # Find the default workflow template for the current user's organization
    default_template = current_user.organization.workflow_templates.default.first

    if default_template.nil?
      @regulation_reviews = []
      flash.now[:alert] = "No default workflow template found for your organization. Please contact an administrator."
      return
    end

    # Find workflow steps that are assigned to the current user's roles
    # and belong to the default template
    assigned_workflow_steps = default_template.workflow_steps.joins(:role)
                                                .where(roles: { name: user_roles })
                                                .pluck(:name)
    
    # Convert step names to the format used in workflow_state (parameterized and underscored)
    assigned_workflow_states = assigned_workflow_steps.map { |name| name.parameterize.underscore }

    # Filter regulation reviews based on the current user's organization and assigned workflow states
    @regulation_reviews = RegulationReview.joins(organization_regulation: :organization)
                                          .where(organization_regulations: { organization_id: current_user.organization_id })
                                          .where(workflow_state: assigned_workflow_states)
                                          .order(created_at: :desc)
    
    if @regulation_reviews.empty? && assigned_workflow_states.any?
      flash.now[:notice] = "No regulation reviews currently assigned to you."
    elsif assigned_workflow_states.empty?
      flash.now[:alert] = "Your roles do not have any workflow steps assigned in the default template."
    end
  end

  def show
    # @regulation_review and @current_step are set by the before_action
    @regulation = @regulation_review.organization_regulation.regulation
    @compliance_frameworks = @regulation_review.organization_regulation.organization.compliance_frameworks.order(:name)
  end

  def update
    # Determine the event. If a decision button was clicked, the event is 'approve'.
    event = params[:event].presence || (params[:decision].present? ? 'approve' : nil)
    decision_notes = params.dig(:regulation_review, :decision_notes)

    # Log the decision if one was made
    if params[:decision].present? && @current_step
      @regulation_review.regulation_review_decisions.create!(
        workflow_step: @current_step,
        user: current_user,
        decision: params[:decision],
        notes: decision_notes
      )
    end

    if event.present? && @regulation_review.respond_to?("#{event}!")
      @regulation_review.send("#{event}!")
      redirect_to regulation_reviews_path, notice: "Review state was successfully updated."
    else
      # If no event, just save the notes
      if @regulation_review.update(decision_notes: decision_notes)
        redirect_to regulation_review_path(@regulation_review), notice: "Notes were successfully saved."
      else
        redirect_to regulation_review_path(@regulation_review), alert: "Invalid action or failed to save notes."
      end
    end
  end

  def classify
    framework_id = params.dig(:organization_regulation, :compliance_framework_id)
    framework = @regulation_review.organization_regulation.organization.compliance_frameworks.find_by(id: framework_id)

    if framework && @regulation_review.organization_regulation.update(compliance_framework: framework)
      # Advance the workflow after successful classification
      @regulation_review.approve! if @regulation_review.can_approve?
      
      redirect_to organization_compliance_framework_path(framework.organization, framework), 
                  notice: "Regulation classified to '#{framework.name}'. You can now break it down into actionable requirements."
    else
      redirect_to regulation_review_path(@regulation_review), alert: 'Failed to classify the regulation. Please select a valid framework.'
    end
  end

  private

  def set_regulation_review
    @regulation_review = RegulationReview.includes(regulation_review_decisions: [:user, :workflow_step]).find(params[:id])
    @current_step = @regulation_review.workflow_template.workflow_steps.find_by(name: @regulation_review.workflow_state.humanize)
    # Authorize access here later
  end
end
