module Api
  module V1
    class StripeController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/stripe/setup-intent
      # Returns a SetupIntent client_secret for adding a payment method
      def create_setup_intent
        customer_id = current_user.get_or_create_stripe_customer

        setup_intent = Stripe::SetupIntent.create(
          customer: customer_id,
          payment_method_types: ['card'],
          metadata: { user_id: current_user.id }
        )

        render json: {
          client_secret: setup_intent.client_secret,
          customer_id: customer_id
        }

      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      # GET /api/v1/stripe/publishable-key
      # Returns the publishable key for the iOS app to initialize Stripe
      def publishable_key
        render json: {
          publishable_key: ENV['STRIPE_PUBLISHABLE_KEY']
        }
      end
    end
  end
end
