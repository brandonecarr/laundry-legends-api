module Api
  module V1
    class SubscriptionsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_subscription, only: [:update]

      def current
        subscription = current_user.subscriptions.where(status: [:active, :paused]).first

        if subscription
          render json: subscription
        else
          render json: { error: 'No active subscription' }, status: 404
        end
      end

      def create
        plan = SubscriptionPlan.find(params[:plan_id])
        payment_method = current_user.payment_methods.find(params[:payment_method_id])

        # Ensure user has a Stripe customer
        customer_id = current_user.get_or_create_stripe_customer

        # Create Stripe subscription
        stripe_subscription = Stripe::Subscription.create(
          customer: customer_id,
          items: [{ price_data: {
            currency: 'usd',
            product_data: { name: plan.name },
            unit_amount: plan.price_cents,
            recurring: { interval: 'month' }
          }}],
          default_payment_method: payment_method.stripe_payment_method_id,
          metadata: {
            user_id: current_user.id,
            plan_id: plan.id
          }
        )

        # Create local subscription record
        subscription = current_user.subscriptions.create!(
          subscription_plan: plan,
          stripe_subscription_id: stripe_subscription.id,
          status: subscription_status_from_stripe(stripe_subscription.status),
          bags_used_this_period: 0,
          current_period_start: Time.at(stripe_subscription.current_period_start).to_date,
          current_period_end: Time.at(stripe_subscription.current_period_end).to_date,
          auto_recurring: params.dig(:auto_recurring, :enabled) || false,
          recurring_day: params.dig(:auto_recurring, :day_of_week),
          recurring_time_window_id: params.dig(:auto_recurring, :time_window_id)
        )

        render json: { subscription: subscription }, status: :created

      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue Stripe::CardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def update
        if params[:status] == 'canceled' && @subscription.stripe_subscription_id
          # Cancel in Stripe
          Stripe::Subscription.cancel(@subscription.stripe_subscription_id)
        elsif params[:status] == 'paused' && @subscription.stripe_subscription_id
          # Pause in Stripe
          Stripe::Subscription.update(
            @subscription.stripe_subscription_id,
            { pause_collection: { behavior: 'void' } }
          )
        elsif params[:status] == 'active' && @subscription.status == 'paused' && @subscription.stripe_subscription_id
          # Resume in Stripe
          Stripe::Subscription.update(
            @subscription.stripe_subscription_id,
            { pause_collection: '' }
          )
        end

        @subscription.update!(subscription_params)
        render json: { subscription: @subscription }

      rescue Stripe::InvalidRequestError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def set_subscription
        @subscription = current_user.subscriptions.find(params[:id])
      end

      def subscription_params
        params.permit(:status, auto_recurring: [:enabled, :day_of_week, :time_window_id]).tap do |p|
          if p[:auto_recurring]
            p[:auto_recurring] = p[:auto_recurring][:enabled]
            p[:recurring_day] = p.delete(:auto_recurring)&.dig(:day_of_week)
            p[:recurring_time_window_id] = p.delete(:auto_recurring)&.dig(:time_window_id)
          end
        end
      end

      def subscription_status_from_stripe(stripe_status)
        case stripe_status
        when 'active', 'trialing'
          :active
        when 'past_due', 'unpaid'
          :paused
        when 'canceled', 'incomplete_expired'
          :canceled
        else
          :active
        end
      end
    end
  end
end
