class JwtService
  # Secret key for JWT encoding/decoding - in production, use Rails.application.credentials
  SECRET_KEY = Rails.application.secret_key_base || "your_secret_key_here"

  # Default expiration time (24 hours)
  DEFAULT_EXPIRATION = 24.hours.from_now

  class << self
    # Generate JWT token for user
    def encode(payload, exp = DEFAULT_EXPIRATION)
      # Add expiration and issued at time to payload
      payload[:exp] = exp.to_i
      payload[:iat] = Time.current.to_i

      begin
        JWT.encode(payload, SECRET_KEY, "HS256")
      rescue => e
        Rails.logger.error "JWT Encoding Error: #{e.message}"
        nil
      end
    end

    # Decode JWT token and return payload
    def decode(token)
      begin
        decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })
        decoded[0] # Return payload (first element of decoded array)
      rescue JWT::ExpiredSignature
        { error: "Token has expired", code: :token_expired }
      rescue JWT::InvalidIatError
        { error: "Invalid issued at time", code: :invalid_iat }
      rescue JWT::DecodeError => e
        { error: "Invalid token format", code: :invalid_token, message: e.message }
      rescue => e
        Rails.logger.error "JWT Decoding Error: #{e.message}"
        { error: "Token processing failed", code: :token_error, message: e.message }
      end
    end

    # Generate token for user authentication
    def generate_user_token(user)
      payload = {
        user_id: user.id,
        email: user.email,
        type: "access_token"
      }
      encode(payload)
    end

    # Generate refresh token with longer expiration
    def generate_refresh_token(user)
      payload = {
        user_id: user.id,
        email: user.email,
        type: "refresh_token"
      }
      # Refresh tokens last 7 days
      encode(payload, 7.days.from_now)
    end

    # Verify token and return user
    def verify_user_token(token)
      return { error: "Token missing", code: :missing_token } if token.blank?

      payload = decode(token)
      return payload if payload.key?(:error) # Return error if decoding failed

      # Check if it's a valid user token
      unless payload["type"] == "access_token"
        return { error: "Invalid token type", code: :invalid_token_type }
      end

      # Find user
      user = User.find_by(id: payload["user_id"])
      unless user
        return { error: "User not found", code: :user_not_found }
      end

      # Verify email matches (additional security check)
      unless user.email == payload["email"]
        return { error: "Token user mismatch", code: :user_mismatch }
      end

      { user: user, payload: payload }
    end

    # Check if token is expired without decoding
    def token_expired?(token)
      payload = decode(token)
      return true if payload.key?(:error)

      exp_time = Time.at(payload["exp"])
      exp_time < Time.current
    rescue
      true # Consider invalid tokens as expired
    end

    # Extract user ID from token without full verification
    def extract_user_id(token)
      payload = decode(token)
      return nil if payload.key?(:error)

      payload["user_id"]
    rescue
      nil
    end
  end
end
