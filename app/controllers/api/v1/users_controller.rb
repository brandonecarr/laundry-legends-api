# app/controllers/api/v1/users_controller.rb

module Api
  module V1
    class UsersController < ApplicationController
      # GET /api/v1/user/profile
      def profile
        render json: {
          user: user_response(current_user)
        }
      end
      
      # PATCH /api/v1/user/profile
      def update
        if current_user.update(update_params)
          render json: {
            user: user_response(current_user)
          }
        else
          render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      private
      
      def update_params
        params.permit(:first_name, :last_name, :phone)
      end
      
      def user_response(user)
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
