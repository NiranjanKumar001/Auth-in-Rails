class DashboardController < ApplicationController
  before_action :require_login

  def index
    @user = current_user
  end

  private

  def require_login
    redirect_to "/login" unless session[:user_id]
  end

  def current_user
    User.find(session[:user_id])
  end
end
