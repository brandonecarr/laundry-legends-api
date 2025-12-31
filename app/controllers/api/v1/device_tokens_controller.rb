module Api
  module V1
    class DeviceTokensController < ApplicationController
      def create
        device_token = current_user.device_tokens.find_or_initialize_by(
          token: params[:token]
        )

        device_token.platform = params[:platform] || 'ios'
        device_token.active = true

        if device_token.save
          render json: {
            message: 'Device token registered successfully',
            device_token: {
              id: device_token.id,
              platform: device_token.platform,
              active: device_token.active
            }
          }, status: :ok
        else
          render json: { error: device_token.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      def destroy
        device_token = current_user.device_tokens.find_by(token: params[:token])

        if device_token
          device_token.update(active: false)
          render json: { message: 'Device token unregistered successfully' }, status: :ok
        else
          render json: { error: 'Device token not found' }, status: :not_found
        end
      end
    end
  end
end
