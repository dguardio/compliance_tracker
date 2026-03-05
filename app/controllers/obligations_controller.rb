class ObligationsController < ApplicationController
  before_action -> { require_feature!(:obligation_management) }
  before_action :set_organization
  before_action :set_obligation, only: %i[show edit update destroy]
  before_action :authorize_obligation

  def index
    @obligations = @organization.obligations.includes(:regulation, :created_by, :compliance_controls)
    @obligations = @obligations.where(status: params[:status]) if params[:status].present?
    @obligations = @obligations.where(priority: params[:priority]) if params[:priority].present?
    @obligations = @obligations.where(obligation_type: params[:type]) if params[:type].present?
    @obligations = @obligations.order(due_date: :asc)

    @stats = {
      total: @organization.obligations.count,
      active: @organization.obligations.active_obligations.count,
      overdue: @organization.obligations.overdue.count,
      due_soon: @organization.obligations.due_soon.count
    }
  end

  def show
  end

  def new
    @obligation = @organization.obligations.build
  end

  def create
    @obligation = @organization.obligations.build(obligation_params)
    @obligation.created_by = current_user

    if @obligation.save
      redirect_to organization_obligation_path(@organization, @obligation),
                  notice: 'Obligation was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @obligation.update(obligation_params)
      redirect_to organization_obligation_path(@organization, @obligation),
                  notice: 'Obligation was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @obligation.destroy
    redirect_to organization_obligations_path(@organization), notice: 'Obligation deleted.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_obligation
    @obligation = @organization.obligations.find(params[:id])
  end

  def obligation_params
    params.require(:obligation).permit(
      :title, :description, :status, :priority, :due_date, :frequency,
      :obligation_type, :source_text, :regulation_id, compliance_control_ids: []
    )
  end

  def authorize_obligation
    case action_name
    when 'index'
      authorize Obligation.new(organization: @organization), :index?
    when 'show'
      authorize @obligation, :show?
    when 'new', 'create'
      authorize Obligation.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @obligation, :update?
    when 'destroy'
      authorize @obligation, :destroy?
    end
  end
end
