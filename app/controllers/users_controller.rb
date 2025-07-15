class UsersController < ApplicationController
  before_action :set_organization
  before_action :set_user, only: %i[show edit update destroy]
  before_action :authorize_user

  def index
    @users = @organization.users.includes(:roles, :department, :team, :unit).page(params[:page]).per(20)
  end

  def show
    @roles = @user.roles
  end

  def new
    @user = @organization.users.build
  end

  def create
    @user = @organization.users.build(user_params)

    if @user.save
      redirect_to organization_user_path(@organization, @user),
                  notice: 'User was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to organization_user_path(@organization, @user),
                  notice: 'User was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to organization_users_path(@organization),
                notice: 'User was successfully deleted.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_user
    @user = @organization.users.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :department_id, :team_id, :unit_id,
                                 :settings)
  end

  def authorize_user
    case action_name
    when 'index'
      authorize User.new(organization: @organization), :index?
    when 'show'
      authorize @user, :show?
    when 'new', 'create'
      authorize User.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @user, :update?
    when 'destroy'
      authorize @user, :destroy?
    end
  end
end
