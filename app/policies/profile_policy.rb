class ProfilePolicy < ApplicationPolicy
  def show?
    # Users can always view their own profile
    user == record
  end

  def edit?
    # Users can always edit their own profile
    user == record
  end

  def update?
    # Users can always update their own profile
    user == record
  end

  def update_password?
    # Users can always update their own password
    user == record
  end

  def update_notifications?
    # Users can always update their own notification settings
    user == record
  end

  def update_preferences?
    # Users can always update their own preferences
    user == record
  end
end 