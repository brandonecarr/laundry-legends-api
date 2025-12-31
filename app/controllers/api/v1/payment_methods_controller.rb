# app/controllers/api/v1/payment_methods_controller.rb
module Api
  module V1
    class PaymentMethodsController < ApplicationController
      before_action :authenticate_user!
      
      def index
        # Get Stripe customer
        customer_id = current_user.stripe_customer_id
        
        if customer_id.blank?
          render json: { payment_methods: [] }, status: :ok
          return
        end
        
        # Fetch payment methods from Stripe
        payment_methods = Stripe::PaymentMethod.list(
          customer: customer_id,
          type: 'card'
        )
        
        # Transform to our format
        formatted_methods = payment_methods.data.map do |pm|
          {
            id: pm.id,
            card: {
              brand: pm.card.brand,
              last4: pm.card.last4,
              exp_month: pm.card.exp_month,
              exp_year: pm.card.exp_year
            },
            is_default: pm.id == current_user.default_payment_method_id
          }
        end
        
        render json: { payment_methods: formatted_methods }, status: :ok
        
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
      
      def create
        # Attach payment method to customer
        token = params[:token]
        
        # Create or get Stripe customer
        if current_user.stripe_customer_id.blank?
          customer = Stripe::Customer.create(
            email: current_user.email,
            name: "#{current_user.first_name} #{current_user.last_name}"
          )
          current_user.update!(stripe_customer_id: customer.id)
        end
        
        # Attach payment method
        payment_method = Stripe::PaymentMethod.attach(
          token,
          { customer: current_user.stripe_customer_id }
        )
        
        # Set as default if requested
        if params[:set_as_default]
          Stripe::Customer.update(
            current_user.stripe_customer_id,
            invoice_settings: { default_payment_method: payment_method.id }
          )
          current_user.update!(default_payment_method_id: payment_method.id)
        end
        
        # Return formatted payment method
        formatted = {
          id: payment_method.id,
          card: {
            brand: payment_method.card.brand,
            last4: payment_method.card.last4,
            exp_month: payment_method.card.exp_month,
            exp_year: payment_method.card.exp_year
          },
          is_default: params[:set_as_default]
        }
        
        render json: { payment_method: formatted }, status: :created
        
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
      
      def set_default
        payment_method_id = params[:id]
        
        Stripe::Customer.update(
          current_user.stripe_customer_id,
          invoice_settings: { default_payment_method: payment_method_id }
        )
        
        current_user.update!(default_payment_method_id: payment_method_id)
        
        render json: { message: 'Default payment method updated' }, status: :ok
        
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
      
      def destroy
        payment_method_id = params[:id]
        
        Stripe::PaymentMethod.detach(payment_method_id)
        
        # If this was default, clear it
        if current_user.default_payment_method_id == payment_method_id
          current_user.update!(default_payment_method_id: nil)
        end
        
        render json: { message: 'Payment method deleted' }, status: :ok
        
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
