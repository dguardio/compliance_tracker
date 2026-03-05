class PoliciesController < ApplicationController
  before_action -> { require_feature!(:policies) }
  before_action :set_policy, only: [:show, :edit, :update, :destroy]
  before_action :set_organization

  def index
    authorize Policy.new(organization: @organization)
    @policies = @organization.policies.order(created_at: :desc)
  end

  def show
    authorize @policy
  end

  def new
    @policy = @organization.policies.build
    authorize @policy
  end

  def edit
    authorize @policy
  end

  def create
    @policy = @organization.policies.build(policy_params)
    authorize @policy

    if @policy.save
      redirect_to organization_policy_path(@organization, @policy), notice: 'Policy was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @policy
    if @policy.update(policy_params)
      redirect_to organization_policy_path(@organization, @policy), notice: 'Policy was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @policy
    @policy.destroy
    redirect_to organization_policies_path(@organization), notice: 'Policy was successfully destroyed.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_policy
    @policy = Policy.find(params[:id])
  end

  def policy_params
    params.require(:policy).permit(:title, :description, :content, :status, :effective_date, :file)
  end
end
