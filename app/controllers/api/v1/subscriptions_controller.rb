module Api
  module V1
    class SubscriptionsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_subscription, only: [:update]
      
      def current
        subscription = current_user.subscriptions.where(status: ['active', 'paused']).last
        
        if subscription
          render json: { subscription: subscription }
        else
          head :not_found
        end
      end
      
      def create
        plan = SubscriptionPlan.find(params[:plan_id])
        payment_method = current_user.payment_methods.find(params[:payment_method_id])
        
        subscription = current_user.subscriptions.create!(
          subscription_plan: plan,
          status: 'active',
          bags_used_this_period: 0,
          current_period_end: 1.month.from_now.to_date,
          auto_recurring_enabled: params.dig(:auto_recurring, :enabled) || false,
          auto_recurring_day_of_week: params.dig(:auto_recurring, :day_of_week),
          auto_recurring_time_window: params.dig(:auto_recurring, :time_window)
        )
        
        # Create first invoice
        Invoice.create!(
          user: current_user,
          subscription: subscription,
          amount_cents: plan.price_cents,
          tax_cents: (plan.price_cents * 0.09).to_i,
          total_cents: plan.price_cents + (plan.price_cents * 0.09).to_i,
          status: 'paid',
          description: "#{plan.name} - Monthly",
          paid_at: Time.current
        )
        
        render json: { subscription: subscription }, status: :created
      end
      
      def update
        @subscription.update!(subscription_params)
        render json: { subscription: @subscription }
      end
      
      private
      
      def set_subscription
        @subscription = current_user.subscriptions.find(params[:id])
      end
      
      def subscription_params
        params.permit(:status, auto_recurring: [:enabled, :day_of_week, :time_window]).tap do |p|
          if p[:auto_recurring]
            p[:auto_recurring_enabled] = p[:auto_recurring][:enabled]
            p[:auto_recurring_day_of_week] = p[:auto_recurring][:day_of_week]
            p[:auto_recurring_time_window] = p[:auto_recurring][:time_window]
            p.delete(:auto_recurring)
          end
        end
      end
    end
  end
end
