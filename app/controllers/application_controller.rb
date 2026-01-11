class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Skip CSRF protection for API requests with JWT
  protect_from_forgery unless: -> { request.format.json? }

  # Helper methods for authentication
  helper_method :current_user, :logged_in?, :jwt_token

  before_action :authenticate_request, if: -> { request.format.json? }

  # Error handling for JWT authentication
  rescue_from JWT::DecodeError, with: :handle_jwt_decode_error
  rescue_from JWT::ExpiredSignature, with: :handle_jwt_expired

  def current_user
    @current_user ||= find_user_from_session_or_token
  end

  def logged_in?
    !!current_user
  end

  def require_login
    unless logged_in?
      respond_to do |format|
        format.html do
          flash[:alert] = "Please log in to access this page."
          redirect_to login_path
        end
        format.json do
          render json: {
            error: "Authentication required",
            message: "Please provide a valid token",
            code: "auth_required"
          }, status: :unauthorized
        end
      end
    end
  end

  # Generate JWT token for current user
  def jwt_token
    return nil unless current_user
    @jwt_token ||= JwtService.generate_user_token(current_user)
  end

  private

  # Find user from session (web) or JWT token (API)
  def find_user_from_session_or_token
    if request.format.json?
      find_user_from_jwt_token
    else
      find_user_from_session
    end
  end

  # Session-based authentication (for web interface)
  def find_user_from_session
    User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # JWT-based authentication (for API requests)
  def find_user_from_jwt_token
    token = extract_token_from_request
    return nil unless token

    result = JwtService.verify_user_token(token)
    return nil if result.key?(:error)

    result[:user]
  end

  # Extract JWT token from request headers or params
  def extract_token_from_request
    # Check Authorization header first
    auth_header = request.headers["Authorization"]
    if auth_header&.start_with?("Bearer ")
      return auth_header.split(" ").last
    end

    # Check token parameter as fallback
    params[:token]
  end

  # Authenticate API requests
  def authenticate_request
    return if current_user

    token = extract_token_from_request
    if token.blank?
      render json: {
        error: "Token missing",
        message: "Authorization token is required",
        code: "missing_token"
      }, status: :unauthorized
      return
    end

    result = JwtService.verify_user_token(token)
    if result.key?(:error)
      render json: {
        error: result[:error],
        code: result[:code]
      }, status: :unauthorized
      return
    end

    @current_user = result[:user]
  end

  # Handle JWT decode errors
  def handle_jwt_decode_error(exception)
    render json: {
      error: "Invalid token format",
      message: exception.message,
      code: "invalid_token"
    }, status: :unauthorized
  end

  # Handle JWT expired token
  def handle_jwt_expired(exception)
    render json: {
      error: "Token has expired",
      message: "Please obtain a new token",
      code: "token_expired"
    }, status: :unauthorized
  end

  # Set JWT token for API responses
  def set_jwt_token_headers
    if current_user && request.format.json?
      response.headers["X-JWT-Token"] = jwt_token
    end
  end
end
