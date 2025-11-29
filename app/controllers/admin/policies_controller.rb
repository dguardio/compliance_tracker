module Admin
  class PoliciesController < ApplicationController
    after_action :verify_authorized
    before_action :set_policy, only: [:show, :edit, :update, :destroy]

    def index
      authorize Policy
      @policies = policy_scope(Policy).order(created_at: :desc)
    end

    def show
      authorize @policy
    end

    def new
      @policy = Policy.new
      authorize @policy
    end

    def edit
      authorize @policy
    end

    def create
      @policy = Policy.new(policy_params)
      authorize @policy

      if @policy.save
        redirect_to admin_policy_path(@policy), notice: 'Policy was successfully created.'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      authorize @policy
      if @policy.update(policy_params)
        redirect_to admin_policy_path(@policy), notice: 'Policy was successfully updated.'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @policy
      @policy.destroy
      redirect_to admin_policies_path, notice: 'Policy was successfully destroyed.'
    end

    private

    def set_policy
      @policy = Policy.find(params[:id])
    end

    def policy_params
      params.require(:policy).permit(:title, :description, :content, :status, :effective_date, :file)
    end
  end
end
