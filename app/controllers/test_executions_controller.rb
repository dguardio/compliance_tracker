class TestExecutionsController < ApplicationController
  before_action -> { require_feature!(:control_testing) }
  before_action :set_organization
  before_action :set_test_plan
  before_action :set_test_execution

  def show
    @test_samples = @test_execution.test_samples.order(:id)
  end

  def update
    # Update samples from form
    if params[:test_samples].present?
      params[:test_samples].each do |sample_id, sample_params|
        sample = @test_execution.test_samples.find(sample_id)
        sample.update!(
          result: sample_params[:result],
          notes: sample_params[:notes],
          tested_at: Time.current
        )
      end
    end

    # Auto-calculate result
    result = @test_execution.calculate_result_from_samples

    if params[:complete] == 'true'
      @test_execution.complete!(result, params[:test_execution]&.dig(:notes))
      redirect_to organization_control_testing_path(@organization, @test_plan),
                  notice: 'Test execution completed and submitted for review.'
    else
      @test_execution.update!(result: result, notes: params[:test_execution]&.dig(:notes))
      redirect_to organization_control_testing_test_execution_path(@organization, @test_plan, @test_execution),
                  notice: 'Sample results saved.'
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_test_plan
    @test_plan = @organization.test_plans.find(params[:control_testing_id])
  end

  def set_test_execution
    @test_execution = @test_plan.test_executions.find(params[:id])
  end
end
