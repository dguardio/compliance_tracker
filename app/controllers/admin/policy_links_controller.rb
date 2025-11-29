module Admin
  class PolicyLinksController < ApplicationController
    before_action :set_policy

    def new
      @policy_link = @policy.policy_links.new
      @linkable_type = params[:linkable_type]
      
      case @linkable_type
      when 'Regulation'
        @linkables = Regulation.all.order(:title)
      when 'ComplianceControl'
        @linkables = current_organization.compliance_controls.active.order(:name)
      when 'RiskAssessment'
        @linkables = current_organization.risk_assessments.active.order(:name)
      else
        redirect_to admin_policy_path(@policy), alert: "Invalid link type."
      end
    end

    def create
      @policy_link = @policy.policy_links.new(policy_link_params)

      if @policy_link.save
        redirect_to admin_policy_path(@policy), notice: 'Link was successfully added.'
      else
        @linkable_type = @policy_link.linkable_type
        case @linkable_type
        when 'Regulation'
          @linkables = Regulation.all.order(:title)
        when 'ComplianceControl'
          @linkables = current_organization.compliance_controls.active.order(:name)
        when 'RiskAssessment'
          @linkables = current_organization.risk_assessments.active.order(:name)
        end
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      @policy_link = @policy.policy_links.find(params[:id])
      @policy_link.destroy
      redirect_to admin_policy_path(@policy), notice: 'Link was successfully removed.'
    end

    private

    def set_policy
      @policy = Policy.find(params[:policy_id])
    end

    def policy_link_params
      params.require(:policy_link).permit(:linkable_type, :linkable_id, :citation, :notes)
    end
  end
end
