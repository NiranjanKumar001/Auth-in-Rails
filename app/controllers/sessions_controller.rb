class SessionsController < ApplicationController
  def new
    redirect_to dashboard_path if logged_in?
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      respond_to do |format|
        format.html do
          session[:user_id] = user.id
          flash[:notice] = "Welcome back, #{user.email}!"
          redirect_to dashboard_path
        end
        format.json do
          token = JwtService.generate_user_token(user)
          refresh_token = JwtService.generate_refresh_token(user)

          if token && refresh_token
            render json: {
              message: "Login successful",
              user: {
                id: user.id,
                email: user.email,
                created_at: user.created_at
              },
              token: token,
              refresh_token: refresh_token,
              expires_at: 24.hours.from_now.iso8601
            }, status: :ok
          else
            render json: {
              error: "Token generation failed",
              code: "token_generation_error"
            }, status: :internal_server_error
          end
        end
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:alert] = "Invalid email or password"
          render :new, status: :unprocessable_entity
        end
        format.json do
          render json: {
            error: "Invalid credentials",
            message: "The email or password provided is incorrect",
            code: "invalid_credentials"
          }, status: :unauthorized
        end
      end
    end
  end

  def destroy
    respond_to do |format|
      format.html do
        session[:user_id] = nil
        flash[:notice] = "You have been logged out."
        redirect_to login_path
      end
      format.json do
        # For JWT, we can't really "destroy" the token on server side
        # The client should discard the token
        render json: {
          message: "Logout successful",
          note: "Please discard your token on the client side"
        }, status: :ok
      end
    end
  end

  # Refresh JWT token endpoint
  def refresh
    refresh_token = params[:refresh_token]

    if refresh_token.blank?
      render json: {
        error: "Refresh token required",
        code: "missing_refresh_token"
      }, status: :bad_request
      return
    end

    result = JwtService.decode(refresh_token)

    if result.key?(:error)
      render json: {
        error: result[:error],
        code: result[:code]
      }, status: :unauthorized
      return
    end

    # Verify it's a refresh token
    unless result["type"] == "refresh_token"
      render json: {
        error: "Invalid token type",
        message: "This endpoint requires a refresh token",
        code: "invalid_token_type"
      }, status: :unauthorized
      return
    end

    user = User.find_by(id: result["user_id"])
    unless user
      render json: {
        error: "User not found",
        code: "user_not_found"
      }, status: :unauthorized
      return
    end

    # Generate new tokens
    new_token = JwtService.generate_user_token(user)
    new_refresh_token = JwtService.generate_refresh_token(user)

    if new_token && new_refresh_token
      render json: {
        message: "Token refreshed successfully",
        token: new_token,
        refresh_token: new_refresh_token,
        expires_at: 24.hours.from_now.iso8601
      }, status: :ok
    else
      render json: {
        error: "Token generation failed",
        code: "token_generation_error"
      }, status: :internal_server_error
    end
  end
end
