# frozen_string_literal: true

class FeedbacksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_feedback, only: %i[show update]
  before_action :set_feedbackable, only: %i[new create]
  after_action :verify_authorized, except: %i[new create] # Add verify_authorized

  def index
    @feedbacks = Feedback.all.order(created_at: :desc) # Will need to scope this to organization later
    authorize @feedbacks # Authorize the collection
  end

  def show
    authorize @feedback
  end

  def new
    @feedback = Feedback.new(feedbackable: @feedbackable)
    authorize @feedback # Authorize the new feedback object
    render layout: false # Render without layout for modal
  end

  def create
    @feedback = @feedbackable.feedbacks.build(feedback_params)
    @feedback.user = current_user
    authorize @feedback # Authorize the feedback object before saving

    if @feedback.save
      # Adjust redirection based on feedbackable type
      if @feedback.feedbackable_type == 'Regulation'
        redirect_to admin_regulation_path(@feedback.feedbackable), notice: 'Feedback was successfully submitted.'
      else
        redirect_to @feedbackable, notice: 'Feedback was successfully submitted.'
      end
    else
      # If feedbackable_type and feedbackable_id are present, redirect back to the source
      # Otherwise, redirect to a default location or show an error.
      if @feedback.feedbackable
        # Adjust redirection based on feedbackable type for error case
        if @feedback.feedbackable_type == 'Regulation'
          redirect_to admin_regulation_path(@feedback.feedbackable), alert: 'Failed to submit feedback.'
        else
          redirect_to @feedbackable, alert: 'Failed to submit feedback.'
        end
      else
        redirect_to root_path, alert: 'Failed to submit feedback and could not determine source.'
      end
    end
  end

  def update
    authorize @feedback # Authorize before update
    if @feedback.update(feedback_params)
      redirect_to @feedback, notice: 'Feedback was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  def set_feedbackable
    feedbackable_type = params[:feedbackable_type]
    feedbackable_id = params[:feedbackable_id]

    # Whitelist of allowed feedbackable types to prevent security issues
    allowed_types = ['ComplianceControl', 'ComplianceRequirement', 'Regulation']

    if feedbackable_type.in?(allowed_types) && feedbackable_id.present?
      @feedbackable = feedbackable_type.constantize.find_by(id: feedbackable_id)
    end

    unless @feedbackable
      redirect_to root_path, alert: 'Could not find the item to provide feedback on.'
    end
  end

  def feedback_params
    params.require(:feedback).permit(:content, :status, :feedbackable_type, :feedbackable_id)
  end
end
