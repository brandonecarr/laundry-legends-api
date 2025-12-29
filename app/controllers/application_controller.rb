# app/controllers/application_controller.rb

class ApplicationController < ActionController::API
  before_action :set_default_response_format
  before_action :authenticate_request
  
  # Make these methods available to all controllers
  attr_reader :current_user
  
  private
  
  def set_default_response_format
    request.format = :json
  end
  
  # Authentication method - checks JWT token and sets current_user
  def authenticate_request
    header = request.headers['Authorization']
    
    if header.blank?
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return
    end
    
    token = header.split(' ').last
    
    begin
      decoded = JsonWebToken.decode(token)
      
      if decoded.nil?
        render json: { error: 'Invalid token' }, status: :unauthorized
        return
      end
      
      # Check token type
      unless decoded['type'] == 'access'
        render json: { error: 'Invalid token type' }, status: :unauthorized
        return
      end
      
      # Find user
      @current_user = User.find_by(id: decoded['user_id'])
      
      if @current_user.nil?
        render json: { error: 'User not found' }, status: :unauthorized
        return
      end
      
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      render json: { error: 'Invalid token' }, status: :unauthorized
    rescue StandardError => e
      Rails.logger.error "Authentication Error: #{e.message}"
      render json: { error: 'Authentication failed' }, status: :unauthorized
    end
  end
  
  # Optional: Helper to require current user (raises exception if not found)
  def current_user!
    @current_user || raise(StandardError, 'No current user')
  end
end
