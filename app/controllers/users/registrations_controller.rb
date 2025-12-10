class Users::RegistrationsController < ApplicationController
  # Skip tenant scoping for registration
  skip_before_action :set_current_tenant

  before_action :authenticate_user!, only: %i[new create]

  def new
    @user = User.new
    @user.organization_id = params[:organization_id] if params[:organization_id].present?
    @user.email = params[:email] if params[:email].present?
    @organizations = Organization.active.order(:name)
  end

  def create
    @user = User.new(user_params)
    @organizations = Organization.active.order(:name)

    # Process settings
    settings = {}
    settings[:first_name] = params[:user][:first_name] if params[:user][:first_name].present?
    settings[:last_name] = params[:user][:last_name] if params[:user][:last_name].present?
    settings[:job_title] = params[:user][:job_title] if params[:user][:job_title].present?
    settings[:phone] = params[:user][:phone] if params[:user][:phone].present?
    settings[:timezone] = params[:user][:timezone] if params[:user][:timezone].present?
    settings[:compliance_preferences] = {}
    settings[:notification_settings] = {}
    settings[:ui_preferences] = {}
    settings[:custom_fields] = {}

    @user.settings = settings

    # Set default role
    @user.add_role(:user) if @user.valid?

    if @user.save
      # Send welcome email or notification
      # UserMailer.welcome_email(@user).deliver_later

      redirect_to dashboard_path, notice: 'User was successfully created and can now sign in.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :email, :password, :password_confirmation,
      :organization_id, :department_id, :team_id, :unit_id,
      :first_name, :last_name, :job_title, :phone, :timezone
    )
  end
end
