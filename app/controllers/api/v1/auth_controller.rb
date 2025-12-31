# app/controllers/api/v1/auth_controller.rb

module Api
  module V1
    class AuthController < ApplicationController
      # Skip authentication for these actions (login/register don't need auth)
      skip_before_action :authenticate_request, only: [:login, :register, :refresh, :forgot_password]
      
      # POST /api/v1/auth/register
      def register
        user = User.new(user_params)
        
        if user.save  # ← Make sure this actually saves to DB
          # Create laundry preferences for new user
          user.create_laundry_preference!(
            detergent_type: 'standard',
            water_temperature: 'warm',
            dry_method: 'machine',
            # ... defaults
          )
          
          access_token = generate_token(user)
          refresh_token = generate_refresh_token(user)
          
          render json: {
            user: user.as_json,
            access_token: access_token,
            refresh_token: refresh_token
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/auth/login
      def login
        user = User.find_by(email: params[:email])
        
        if user&.authenticate(params[:password])
          tokens = generate_tokens(user)
          render json: {
            user: user_json(user),
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token]
          }
        else
          render json: { error: 'Invalid credentials' }, status: :unauthorized
        end
      end
      
      # POST /api/v1/auth/logout
      def logout
        # For now, logout is handled client-side by deleting the token
        # In the future, you could add token blacklisting here
        render json: { message: 'Logged out successfully' }
      end
      
      # POST /api/v1/auth/refresh
      def refresh
        refresh_token = params[:refresh_token]
        
        if refresh_token.blank?
          render json: { error: 'Refresh token required' }, status: :bad_request
          return
        end
        
        begin
          decoded = JsonWebToken.decode(refresh_token)
          
          if decoded.nil?
            render json: { error: 'Invalid refresh token' }, status: :unauthorized
            return
          end
          
          # Check token type
          unless decoded['type'] == 'refresh'
            render json: { error: 'Invalid token type' }, status: :unauthorized
            return
          end
          
          user = User.find_by(id: decoded['user_id'])
          
          if user.nil?
            render json: { error: 'User not found' }, status: :unauthorized
            return
          end
          
          # Generate new tokens
          tokens = generate_tokens(user)
          render json: {
            access_token: tokens[:access_token],
            refresh_token: tokens[:refresh_token]
          }
          
        rescue StandardError => e
          Rails.logger.error "Token refresh error: #{e.message}"
          render json: { error: 'Token refresh failed' }, status: :unauthorized
        end
      end
      
      # POST /api/v1/auth/forgot-password
      def forgot_password
        email = params[:email]
        
        if email.blank?
          render json: { error: 'Email is required' }, status: :bad_request
          return
        end
        
        user = User.find_by(email: email)
        
        # Always return success (don't reveal if user exists)
        render json: {
          message: 'If an account exists with that email, you will receive password reset instructions.'
        }
        
        # Send reset email if user exists
        # UserMailer.password_reset(user).deliver_later if user
      end
      
      private
      
      def user_params
        params.permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone)
      end
      
      def generate_tokens(user)
        {
          access_token: JsonWebToken.encode(
            {
              user_id: user.id,
              type: 'access'
            },
            JsonWebToken::ACCESS_TOKEN_EXPIRATION
          ),
          refresh_token: JsonWebToken.encode(
            {
              user_id: user.id,
              type: 'refresh'
            },
            JsonWebToken::REFRESH_TOKEN_EXPIRATION
          )
        }
      end
      
      def user_json(user)
        {
          id: user.id,
          email: user.email,
          first_name: user.first_name,
          last_name: user.last_name,
          phone: user.phone,
          role: user.role,
          created_at: user.created_at
        }
      end
    end
  end
end
