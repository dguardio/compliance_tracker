class Admin::ComplianceAssistantController < ApplicationController
  def chat
    question = params[:question]
    regulation_ids = params[:regulation_ids] || []

    service = Ai::ComplianceAssistantService.new(organization: current_organization)
    response = service.ask(question, regulation_ids: regulation_ids)

    render json: { response: response }
  rescue => e
    Rails.logger.error("AI Assistant error: #{e.message}")
    render json: { error: "Sorry, I encountered an error. Please try again." }, status: :unprocessable_entity
  end
end

