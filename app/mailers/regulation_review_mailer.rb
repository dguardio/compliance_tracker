# frozen_string_literal: true

class RegulationReviewMailer < ApplicationMailer
  def review_assigned
    @user = params[:recipient]
    @regulation_review = params[:regulation_review]
    @new_state = params[:new_state]

    mail(to: @user.email, subject: "Action Required: Regulation Review - #{@regulation_review.organization_regulation.regulation.title}")
  end
end
