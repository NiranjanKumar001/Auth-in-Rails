class DashboardController < ApplicationController
  before_action :require_login

  def index
    @user = current_user

    respond_to do |format|
      format.html # Render HTML view
      format.json do
        render json: {
          message: "Dashboard accessed successfully",
          user: {
            id: @user.id,
            email: @user.email,
            created_at: @user.created_at
          },
          stats: {
            total_users: User.count,
            account_age_days: (Time.current - @user.created_at).to_i / 1.day
          }
        }
      end
    end
  end
end
