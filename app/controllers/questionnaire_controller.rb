class QuestionnaireController < ApplicationController
  before_action -> { require_feature!(:questionnaire_autofill) }
  before_action :set_organization
  before_action :authorize_questionnaire

  def index
    @uploads = QuestionnaireUpload.where(organization: @organization).recent.limit(20)
  end

  def show
    @upload = QuestionnaireUpload.where(organization: @organization).find(params[:id])
    @answers = @upload.questionnaire_answers.order(:id)
  end

  def upload
    unless params[:file].present?
      redirect_to organization_questionnaire_index_path(@organization), alert: 'Please select a file.'
      return
    end

    upload = QuestionnaireUpload.create!(
      organization: @organization,
      uploaded_by: current_user,
      filename: params[:file].original_filename,
      status: :processing
    )
    upload.file.attach(params[:file])

    service = QuestionnaireAutofillService.new(@organization)
    service.process(upload)

    redirect_to organization_questionnaire_path(@organization, upload),
                notice: "Questionnaire processed. #{upload.response_count} answers generated."
  rescue StandardError => e
    redirect_to organization_questionnaire_index_path(@organization),
                alert: "Processing failed: #{e.message}"
  end

  def approve_answer
    answer = QuestionnaireAnswer.find(params[:answer_id])
    final_answer = params[:approved_answer].presence || answer.ai_answer
    answer.approve!(final_answer)

    redirect_to organization_questionnaire_path(@organization, answer.questionnaire_upload),
                notice: 'Answer approved.'
  end

  def export
    upload = QuestionnaireUpload.where(organization: @organization).find(params[:id])
    service = QuestionnaireAutofillService.new(@organization)
    csv_data = service.export_csv(upload)

    upload.update!(status: :exported)

    send_data csv_data,
              filename: "#{upload.filename.gsub(/\.[^.]+$/, '')}_completed.csv",
              type: 'text/csv'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def authorize_questionnaire
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
