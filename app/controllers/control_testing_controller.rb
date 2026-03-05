class ControlTestingController < ApplicationController
  before_action -> { require_feature!(:control_testing) }
  before_action :set_organization
  before_action :set_test_plan, only: %i[show edit update destroy execute review]
  before_action :set_test_execution, only: %i[review]
  before_action :authorize_test_plan

  def index
    @test_plans = @organization.test_plans.includes(:compliance_control, :created_by)

    # Filters
    @test_plans = @test_plans.where(status: params[:status]) if params[:status].present?
    @test_plans = @test_plans.where(frequency: params[:frequency]) if params[:frequency].present?

    @test_plans = @test_plans.order(next_due_date: :asc)

    # Dashboard stats
    @stats = {
      total: @organization.test_plans.count,
      active: @organization.test_plans.status_active.count,
      overdue: @organization.test_plans.overdue.count,
      due_soon: @organization.test_plans.due_soon.count
    }
  end

  def show
    @test_executions = @test_plan.test_executions.includes(:tester, :reviewer).order(created_at: :desc)
    @latest_execution = @test_plan.latest_execution
  end

  def new
    @test_plan = @organization.test_plans.build
    @controls = @organization.compliance_controls
  end

  def create
    @test_plan = @organization.test_plans.build(test_plan_params)
    @test_plan.created_by = current_user

    if @test_plan.save
      redirect_to organization_control_testing_path(@organization, @test_plan),
                  notice: 'Test plan was successfully created.'
    else
      @controls = @organization.compliance_controls
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @controls = @organization.compliance_controls
  end

  def update
    if @test_plan.update(test_plan_params)
      redirect_to organization_control_testing_path(@organization, @test_plan),
                  notice: 'Test plan was successfully updated.'
    else
      @controls = @organization.compliance_controls
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @test_plan.destroy
    redirect_to organization_control_testing_index_path(@organization),
                notice: 'Test plan was successfully deleted.'
  end

  # POST /organizations/:org_id/control_testing/:id/execute
  def execute
    execution = @test_plan.test_executions.create!(
      tester: current_user,
      status: :in_progress,
      started_at: Time.current
    )

    # Pre-populate sample slots if sample count provided
    sample_count = (params[:sample_count] || 5).to_i
    sample_count.times do |i|
      execution.test_samples.create!(
        sample_identifier: "Sample #{i + 1}",
        result: :not_tested
      )
    end

    redirect_to organization_control_testing_test_execution_path(@organization, @test_plan, execution),
                notice: 'Test execution started. Record your sample results below.'
  end

  # PATCH /organizations/:org_id/control_testing/:test_plan_id/test_executions/:id/review
  def review
    if params[:approve]
      @test_execution.approve!(current_user, params[:reviewer_notes])
      notice = 'Test execution approved and signed off.'
    else
      @test_execution.reject!(current_user, params[:reviewer_notes])
      notice = 'Test execution rejected.'
    end

    redirect_to organization_control_testing_path(@organization, @test_plan), notice: notice
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_test_plan
    @test_plan = @organization.test_plans.find(params[:id])
  end

  def set_test_execution
    @test_execution = @test_plan.test_executions.find(params[:test_execution_id] || params[:execution_id])
  end

  def test_plan_params
    params.require(:test_plan).permit(
      :title, :description, :frequency, :status, :procedures,
      :compliance_control_id, :next_due_date
    )
  end

  def authorize_test_plan
    case action_name
    when 'index'
      authorize TestPlan.new(organization: @organization), :index?
    when 'show', 'execute', 'review'
      authorize @test_plan, :show?
    when 'new', 'create'
      authorize TestPlan.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @test_plan, :update?
    when 'destroy'
      authorize @test_plan, :destroy?
    end
  end
end
