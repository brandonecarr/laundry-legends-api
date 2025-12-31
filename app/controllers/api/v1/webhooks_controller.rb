module Api
  module V1
    class WebhooksController < ApplicationController
      skip_before_action :authenticate_request
      skip_before_action :verify_authenticity_token, raise: false

      def stripe
        payload = request.body.read
        sig_header = request.env['HTTP_STRIPE_SIGNATURE']
        endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

        begin
          event = Stripe::Webhook.construct_event(
            payload, sig_header, endpoint_secret
          )
        rescue JSON::ParserError => e
          Rails.logger.error "Stripe webhook JSON parse error: #{e.message}"
          return head :bad_request
        rescue Stripe::SignatureVerificationError => e
          Rails.logger.error "Stripe webhook signature verification failed: #{e.message}"
          return head :bad_request
        end

        # Handle the event
        case event.type
        when 'payment_method.attached'
          handle_payment_method_attached(event.data.object)
        when 'payment_method.detached'
          handle_payment_method_detached(event.data.object)
        when 'customer.subscription.created'
          handle_subscription_created(event.data.object)
        when 'customer.subscription.updated'
          handle_subscription_updated(event.data.object)
        when 'customer.subscription.deleted'
          handle_subscription_deleted(event.data.object)
        when 'invoice.payment_succeeded'
          handle_invoice_paid(event.data.object)
        when 'invoice.payment_failed'
          handle_invoice_payment_failed(event.data.object)
        else
          Rails.logger.info "Unhandled Stripe event type: #{event.type}"
        end

        head :ok
      end

      private

      def handle_payment_method_attached(payment_method)
        Rails.logger.info "Payment method attached: #{payment_method.id}"
        # Payment method is attached via API, so we already handle it there
      end

      def handle_payment_method_detached(payment_method)
        Rails.logger.info "Payment method detached: #{payment_method.id}"
        # Remove from our database if it exists
        PaymentMethod.find_by(stripe_payment_method_id: payment_method.id)&.destroy
      end

      def handle_subscription_created(subscription)
        Rails.logger.info "Subscription created: #{subscription.id}"

        user = User.find_by(stripe_customer_id: subscription.customer)
        return unless user

        # Check if subscription already exists
        existing = user.subscription
        return if existing&.stripe_subscription_id == subscription.id

        # Find plan based on price (you may need to adjust this logic)
        plan = SubscriptionPlan.find_by(is_active: true)
        return unless plan

        if existing
          # Update existing subscription record
          existing.update!(
            subscription_plan: plan,
            stripe_subscription_id: subscription.id,
            status: subscription_status_to_enum(subscription.status),
            current_period_start: Time.at(subscription.current_period_start).to_date,
            current_period_end: Time.at(subscription.current_period_end).to_date
          )
        else
          user.create_subscription!(
            subscription_plan: plan,
            stripe_subscription_id: subscription.id,
            status: subscription_status_to_enum(subscription.status),
            current_period_start: Time.at(subscription.current_period_start).to_date,
            current_period_end: Time.at(subscription.current_period_end).to_date
          )
        end
      end

      def handle_subscription_updated(subscription)
        Rails.logger.info "Subscription updated: #{subscription.id}"

        user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
        return unless user_subscription

        user_subscription.update!(
          status: subscription_status_to_enum(subscription.status),
          current_period_start: Time.at(subscription.current_period_start).to_date,
          current_period_end: Time.at(subscription.current_period_end).to_date
        )
      end

      def handle_subscription_deleted(subscription)
        Rails.logger.info "Subscription deleted: #{subscription.id}"

        user_subscription = Subscription.find_by(stripe_subscription_id: subscription.id)
        return unless user_subscription

        user_subscription.update!(status: :canceled)
      end

      def handle_invoice_paid(invoice)
        Rails.logger.info "Invoice paid: #{invoice.id}"

        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        # Find or create invoice record
        existing_invoice = user.invoices.find_by(stripe_invoice_id: invoice.id)
        if existing_invoice
          existing_invoice.update!(status: 'paid', paid_at: Time.current)
        else
          # Find subscription if this is a subscription invoice
          subscription = user.subscription if invoice.subscription && user.subscription&.stripe_subscription_id == invoice.subscription

          user.invoices.create!(
            stripe_invoice_id: invoice.id,
            invoice_number: invoice.number || "INV-#{SecureRandom.hex(4).upcase}",
            subscription: subscription,
            amount_cents: invoice.amount_paid,
            tax_cents: invoice.tax || 0,
            total_cents: invoice.total,
            status: 'paid',
            paid_at: Time.current,
            description: invoice.description || "Subscription payment"
          )
        end

        # Reset bags_used_this_period if this is a subscription renewal
        if invoice.subscription && user.subscription&.stripe_subscription_id == invoice.subscription
          user.subscription.update!(bags_used_this_period: 0)
        end
      end

      def handle_invoice_payment_failed(invoice)
        Rails.logger.info "Invoice payment failed: #{invoice.id}"

        user = User.find_by(stripe_customer_id: invoice.customer)
        return unless user

        # Update or create invoice with failed status
        existing_invoice = user.invoices.find_by(stripe_invoice_id: invoice.id)
        if existing_invoice
          existing_invoice.update!(status: 'failed')
        else
          subscription = user.subscription if invoice.subscription && user.subscription&.stripe_subscription_id == invoice.subscription

          user.invoices.create!(
            stripe_invoice_id: invoice.id,
            invoice_number: invoice.number || "INV-#{SecureRandom.hex(4).upcase}",
            subscription: subscription,
            amount_cents: invoice.amount_due,
            tax_cents: invoice.tax || 0,
            total_cents: invoice.total,
            status: 'failed',
            description: invoice.description || "Failed payment"
          )
        end

        # Send notification about failed payment (if job exists)
        if defined?(SendNotificationJob)
          SendNotificationJob.perform_later(
            user_id: user.id,
            notification_type: 'payment_failed',
            channels: [:push, :sms]
          )
        end
      end

      def subscription_status_to_enum(stripe_status)
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
