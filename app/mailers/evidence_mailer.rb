class EvidenceMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.evidence_mailer.request_email.subject
  #
  def request_email
    @comment = params[:comment]
    @assignee = @comment.assignee
    @requester = @comment.user
    # TODO: Handle polymorphic URL generation better
    @url = workspace_admin_regulation_url(@comment.commentable) if @comment.commentable.is_a?(Regulation)

    mail(to: @assignee.email, subject: "Evidence Request: #{@comment.commentable.try(:title) || 'Compliance Item'}")
  end
end
