# config/initializers/jwt.rb

module JsonWebToken
  SECRET_KEY = Rails.application.credentials.secret_key_base || 'development_secret'
  ALGORITHM = 'HS256'
  
  # Token expiration times
  ACCESS_TOKEN_EXPIRATION = 24.hours
  REFRESH_TOKEN_EXPIRATION = 30.days
  
  class << self
    def encode(payload, exp = ACCESS_TOKEN_EXPIRATION)
      payload[:exp] = exp.from_now.to_i
      # Use ::JWT to call the gem, not the module
      ::JWT.encode(payload, SECRET_KEY, ALGORITHM)
    end
    
    def decode(token)
      # Use ::JWT to call the gem, not the module
      decoded = ::JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })[0]
      HashWithIndifferentAccess.new(decoded)
    rescue ::JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      nil
    end
  end
end
