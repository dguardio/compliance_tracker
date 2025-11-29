module Admin
  class CommentsController < ApplicationController
    before_action :set_commentable, only: [:create]

    def create
      @comment = @commentable.comments.new(comment_params)
      @comment.user = current_user
      @comment.status = :open
      authorize @comment

      if @comment.save
        if @comment.evidence_request? && @comment.assignee.present?
          EvidenceMailer.with(comment: @comment).request_email.deliver_later
        end

        render json: { 
          id: @comment.id, 
          content: @comment.content, 
          user: @comment.user.full_name,
          created_at: @comment.created_at.strftime("%b %d, %Y"),
          start_index: @comment.start_index,
          end_index: @comment.end_index,
          comment_type: @comment.comment_type,
          suggested_text: @comment.suggested_text,
          assignee: @comment.assignee&.full_name
        }, status: :created
      else
        render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      @comment = Comment.find(params[:id])
      authorize @comment
      @comment.destroy
      head :no_content
    end

    private

    def set_commentable
      if params[:regulation_id]
        @commentable = Regulation.find(params[:regulation_id])
      elsif params[:policy_id]
        @commentable = Policy.find(params[:policy_id])
      elsif params[:compliance_requirement_id]
        @commentable = ComplianceRequirement.find(params[:compliance_requirement_id])
      elsif params[:compliance_control_id]
        @commentable = ComplianceControl.find(params[:compliance_control_id])
      end
    end

    def comment_params
      params.require(:comment).permit(:content, :selected_text, :start_index, :end_index, :comment_type, :suggested_text, :assignee_id)
    end
  end
end
