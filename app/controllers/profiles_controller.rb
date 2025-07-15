class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :authorize_profile

  def show
    @user = current_user
    @roles = @user.roles
    @notifications = @user.notifications.order(created_at: :desc).limit(5)
  end

  def edit
    @user = current_user
    @departments = @user.organization.departments
    @teams = @user.department&.teams || []
    @units = @user.team&.units || []
  end

  def update
    if @user.update(profile_params)
      redirect_to profile_path, notice: 'Profile was successfully updated.'
    else
      @departments = @user.organization.departments
      @teams = @user.department&.teams || []
      @units = @user.team&.units || []
      render :edit, status: :unprocessable_entity
    end
  end

  def update_password
    if @user.update_with_password(password_params)
      bypass_sign_in(@user)
      redirect_to profile_path, notice: 'Password was successfully updated.'
    else
      redirect_to profile_path, alert: 'Failed to update password. Please check your current password.'
    end
  end

  def update_notifications
    notification_settings = params[:notification_settings] || {}

    # Update notification settings in user settings
    current_settings = @user.settings || {}
    current_settings[:notification_settings] = notification_settings
    @user.settings = current_settings

    if @user.save
      redirect_to profile_path, notice: 'Notification settings were successfully updated.'
    else
      redirect_to profile_path, alert: 'Failed to update notification settings.'
    end
  end

  def update_preferences
    preferences = params[:preferences] || {}

    # Update UI preferences in user settings
    current_settings = @user.settings || {}
    current_settings[:ui_preferences] = preferences
    @user.settings = current_settings

    if @user.save
      redirect_to profile_path, notice: 'Preferences were successfully updated.'
    else
      redirect_to profile_path, alert: 'Failed to update preferences.'
    end
  end

  private

  def set_user
    @user = current_user
  end

  def authorize_profile
    case action_name
    when 'show'
      authorize @user, :show?
    when 'edit', 'update'
      authorize @user, :update?
    when 'update_password'
      authorize @user, :update_password?
    when 'update_notifications'
      authorize @user, :update_notifications?
    when 'update_preferences'
      authorize @user, :update_preferences?
    end
  end

  def profile_params
    params.require(:user).permit(
      :department_id, :team_id, :unit_id,
      :first_name, :last_name, :job_title, :phone, :timezone
    )
  end

  def password_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end
end
