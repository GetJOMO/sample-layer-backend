require "#{Rails.root}/lib/server_api"

class UsersController < ApplicationController
  before_action :check_login, except: [:new, :create]
  before_action :check_create, only: [:new, :create]

  def index
    @users = User.all.order(id: :asc)
    respond_to do |format|
      format.html
      format.json { render json: { users: @users } }
    end
  end

  include UsersHelper
  def new
    @force_admin = !app_has_admin?
  end

  def show
    find_user
    respond_to do |format|
      format.html
      format.json { render json: @user }
    end
  end

  def create
    params = user_params
    # Force admin creation if app currently doesn't have an admin
    params = params.merge(is_admin: true) unless app_has_admin?
    @user = User.create(params)
    ServerAPI.new.create_identity(@user.id, @user.as_identity)
    redirect_to @user
  end

  def edit
    find_user
  end

  def update
    find_user
    if @user.update_attributes(user_params)
      redirect_to @user
    else
      render text: 'Error updating user fields'
    end
  end

  private
  def find_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :display_name, :first_name, :last_name, :password, :is_admin)
  end

  include SessionsHelper
  def check_login
    if valid_session?
      true
    elsif app_has_admin?
      redirect_to(login_path)
    else
      redirect_to(new_user_path)
    end
  end

  def check_create
    if valid_session? || !app_has_admin?
      true
    else
      redirect_to(login_path)
    end
  end
end
