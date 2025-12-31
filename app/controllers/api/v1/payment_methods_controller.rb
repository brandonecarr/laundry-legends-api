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
        # Get or create Stripe customer
        customer_id = current_user.get_or_create_stripe_customer

        # Attach the payment method to the customer
        stripe_pm = Stripe::PaymentMethod.attach(
          params[:payment_method_id],
          { customer: customer_id }
        )

        # Set as default if requested or if first payment method
        if params[:set_as_default] || current_user.payment_methods.empty?
          Stripe::Customer.update(
            customer_id,
            { invoice_settings: { default_payment_method: stripe_pm.id } }
          )
        end

        # Create local payment method record
        payment_method = current_user.payment_methods.create!(
          stripe_payment_method_id: stripe_pm.id,
          payment_type: stripe_pm.type,
          brand: stripe_pm.card&.brand,
          last_four: stripe_pm.card&.last4,
          expiry_month: stripe_pm.card&.exp_month,
          expiry_year: stripe_pm.card&.exp_year,
          funding: stripe_pm.card&.funding,
          is_default: params[:set_as_default] || current_user.payment_methods.count == 1
        )

        render json: { payment_method: payment_method }, status: :created

      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Stripe::CardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        # Detach from Stripe
        begin
          Stripe::PaymentMethod.detach(@payment_method.stripe_payment_method_id)
        rescue Stripe::InvalidRequestError => e
          Rails.logger.warn "Failed to detach payment method from Stripe: #{e.message}"
        end

        # If deleting default, set another as default
        was_default = @payment_method.is_default?
        @payment_method.destroy!

        if was_default
          new_default = current_user.payment_methods.first
          new_default&.update!(is_default: true)

          # Update Stripe default if we have a new default
          if new_default && current_user.stripe_customer_id
            Stripe::Customer.update(
              current_user.stripe_customer_id,
              { invoice_settings: { default_payment_method: new_default.stripe_payment_method_id } }
            )
          end
        end

        render json: { message: 'Payment method deleted' }
      end

      def set_default
        # Update Stripe default
        if current_user.stripe_customer_id
          Stripe::Customer.update(
            current_user.stripe_customer_id,
            { invoice_settings: { default_payment_method: @payment_method.stripe_payment_method_id } }
          )
        end

        @payment_method.update!(is_default: true)
        render json: { payment_method: @payment_method }

      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_payment_method
        @payment_method = current_user.payment_methods.find(params[:id])
      end
    end
  end
end
