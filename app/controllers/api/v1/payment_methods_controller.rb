module Api
  module V1
    class PaymentMethodsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_payment_method, only: [:destroy, :set_default]
      
      def index
        methods = current_user.payment_methods.order(is_default: :desc, created_at: :desc)
        render json: { payment_methods: methods }
      end
      
      def create
        # Mock payment method for now (Stripe integration later)
        payment_method = current_user.payment_methods.create!(
          stripe_payment_method_id: params[:token],
          type: 'card',
          card_brand: 'visa',
          card_last4: '4242',
          card_expiry_month: 12,
          card_expiry_year: 2025,
          card_funding: 'credit',
          is_default: params[:set_as_default] || false
        )
        
        render json: { payment_method: payment_method }, status: :created
      end
      
      def destroy
        @payment_method.destroy!
        render json: { message: 'Payment method deleted' }
      end
      
      def set_default
        @payment_method.update!(is_default: true)
        render json: { payment_method: @payment_method }
      end
      
      private
      
      def set_payment_method
        @payment_method = current_user.payment_methods.find(params[:id])
      end
    end
  end
end
