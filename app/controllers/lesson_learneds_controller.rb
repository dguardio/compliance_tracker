class LessonLearnedsController < ApplicationController
  before_action -> { require_feature!(:incident_management) }
  before_action :set_organization
  before_action :set_incident

  def create
    @lesson = @incident.lesson_learneds.build(lesson_params)
    @lesson.created_by = current_user

    if @lesson.save
      redirect_to organization_incident_path(@organization, @incident),
                  notice: 'Lesson learned was successfully added.'
    else
      @lessons = @incident.lesson_learneds.includes(:created_by).recent
      @new_lesson = @lesson
      render 'incidents/show', status: :unprocessable_entity
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_incident
    @incident = @organization.incidents.find(params[:incident_id])
  end

  def lesson_params
    params.require(:lesson_learned).permit(:title, :description, :recommendations, :category)
  end
end
