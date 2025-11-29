module Admin
  class EvidenceController < ApplicationController
    def index
      authorize Comment, :index?
      
      @q = policy_scope(Comment).where(comment_type: :evidence_request).ransack(params[:q])
      @evidence_requests = @q.result(distinct: true)
                             .includes(:user, :assignee, :commentable)
                             .order(created_at: :desc)
                             .page(params[:page])
    end
  end
end
