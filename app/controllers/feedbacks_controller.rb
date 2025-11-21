# frozen_string_literal: true

class FeedbacksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_feedback, only: %i[show update]
  before_action :set_feedbackable, only: %i[new create]

  def index
    @feedbacks = Feedback.all.order(created_at: :desc) # Will need to scope this to organization later
  end

  def show
  end

  def new
    @feedback = Feedback.new(feedbackable: @feedbackable)
    render layout: false # Render without layout for modal
  end

  def create
    @feedback = @feedbackable.feedbacks.build(feedback_params)
    @feedback.user = current_user

    if @feedback.save
      redirect_to @feedbackable, notice: 'Feedback was successfully submitted.'
    else
      render :new, status: :unprocessable_entity, layout: false
    end
  end

  def update
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
    params.require(:feedback).permit(:content, :status)
  end
end
