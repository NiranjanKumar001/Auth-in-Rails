class UsersController < ApplicationController
  before_action :require_login, only: [ :index ]

  def index
    @users = User.all.order(created_at: :desc)

    respond_to do |format|
      format.html # Render HTML view
      format.json do
        render json: {
          users: @users.map do |user|
            {
              id: user.id,
              email: user.email,
              created_at: user.created_at,
              is_current_user: user == current_user
            }
          end,
          total_count: @users.count
        }
      end
    end
  end

  def new
    redirect_to dashboard_path if logged_in?
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      respond_to do |format|
        format.html do
          session[:user_id] = @user.id
          flash[:notice] = "Account created successfully! Welcome, #{@user.email}!"
          redirect_to dashboard_path
        end
        format.json do
          token = JwtService.generate_user_token(@user)
          refresh_token = JwtService.generate_refresh_token(@user)

          if token && refresh_token
            render json: {
              message: "Account created successfully",
              user: {
                id: @user.id,
                email: @user.email,
                created_at: @user.created_at
              },
              token: token,
              refresh_token: refresh_token,
              expires_at: 24.hours.from_now.iso8601
            }, status: :created
          else
            render json: {
              error: "Account created but token generation failed",
              code: "token_generation_error"
            }, status: :internal_server_error
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:alert] = "There were errors creating your account."
          render :new, status: :unprocessable_entity
        end
        format.json do
          render json: {
            error: "Validation failed",
            message: "Please check your input and try again",
            errors: @user.errors.full_messages,
            code: "validation_error"
          }, status: :unprocessable_entity
        end
      end
    end
  end

  # API endpoint to get current user info
  def me
    respond_to do |format|
      format.json do
        if current_user
          render json: {
            user: {
              id: current_user.id,
              email: current_user.email,
              created_at: current_user.created_at
            }
          }, status: :ok
        else
          render json: {
            error: "Not authenticated",
            code: "not_authenticated"
          }, status: :unauthorized
        end
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
