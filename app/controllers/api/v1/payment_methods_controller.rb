# app/controllers/api/v1/payment_methods_controller.rb
module Api
  module V1
    class PaymentMethodsController < ApplicationController
      before_action :authenticate_user!

      def index
        customer_id = current_user.stripe_customer_id

        if customer_id.blank?
          render json: { payment_methods: [] }, status: :ok
          return
        end

        # Get customer to find default payment method
        customer = Stripe::Customer.retrieve(customer_id)
        default_pm_id = customer.invoice_settings&.default_payment_method

        # Fetch payment methods from Stripe
        payment_methods = Stripe::PaymentMethod.list(
          customer: customer_id,
          type: 'card'
        )

        # Transform to our format
        formatted_methods = payment_methods.data.map do |pm|
          {
            id: pm.id,
            user_id: current_user.id,
            type: 'card',
            card: {
              brand: pm.card.brand,
              last4: pm.card.last4,
              expiry_month: pm.card.exp_month,
              expiry_year: pm.card.exp_year,
              funding: pm.card.funding
            },
            is_default: pm.id == default_pm_id,
            created_at: pm.created ? Time.at(pm.created).iso8601 : nil
          }
        end

        render json: { payment_methods: formatted_methods }, status: :ok

      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def create
        payment_method_id = params[:token] || params[:payment_method_id]

        if payment_method_id.blank?
          render json: { error: 'Payment method ID is required' }, status: :bad_request
          return
        end

        # Create or get Stripe customer
        customer_id = current_user.get_or_create_stripe_customer

        # Attach payment method to customer
        payment_method = Stripe::PaymentMethod.attach(
          payment_method_id,
          { customer: customer_id }
        )

        # Set as default if requested or if first payment method
        if params[:set_as_default] || params[:setAsDefault]
          Stripe::Customer.update(
            customer_id,
            invoice_settings: { default_payment_method: payment_method.id }
          )
        end

        # Return formatted payment method
        formatted = {
          id: payment_method.id,
          user_id: current_user.id,
          type: 'card',
          card: {
            brand: payment_method.card.brand,
            last4: payment_method.card.last4,
            expiry_month: payment_method.card.exp_month,
            expiry_year: payment_method.card.exp_year,
            funding: payment_method.card.funding
          },
          is_default: params[:set_as_default] || params[:setAsDefault] || false,
          created_at: payment_method.created ? Time.at(payment_method.created).iso8601 : Time.current.iso8601
        }

        render json: { payment_method: formatted }, status: :created

      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def set_default
        payment_method_id = params[:id]

        if current_user.stripe_customer_id.blank?
          render json: { error: 'No Stripe customer found' }, status: :bad_request
          return
        end

        Stripe::Customer.update(
          current_user.stripe_customer_id,
          invoice_settings: { default_payment_method: payment_method_id }
        )

        render json: { message: 'Default payment method updated' }, status: :ok

      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        payment_method_id = params[:id]

        Stripe::PaymentMethod.detach(payment_method_id)

        render json: { message: 'Payment method deleted' }, status: :ok

      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end
