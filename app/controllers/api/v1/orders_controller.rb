module Api
  module V1
    class OrdersController < ApplicationController
      before_action :authenticate_request
      
      # GET /api/v1/orders/next-pickup
      def next_pickup
        order = current_user.orders
                           .includes(:address, :pickup_time_window, :delivery_time_window)
                           .where(status: [:scheduled, :picked_up, :in_cleaning, :quality_check, :out_for_delivery])
                           .order(pickup_date: :asc)
                           .first
        
        if order
          render json: { order: order_json(order) }
        else
          render json: { order: nil }, status: :ok
        end
      end
      
      # GET /api/v1/orders
      def index
        orders = current_user.orders
                            .includes(:address, :pickup_time_window)
                            .order(created_at: :desc)
        
        render json: { orders: orders.map { |o| order_json(o) } }
      end
      
      # GET /api/v1/orders/:id
      def show
        order = current_user.orders
                           .includes(:address, :pickup_time_window, :delivery_time_window)
                           .find(params[:id])
        
        render json: { order: order_json_detailed(order) }
      end
      
      # POST /api/v1/orders/create
      def create
        pickup_date = Date.parse(params[:order][:pickup_date])
        delivery_date = pickup_date + 3.days
        bag_count = params[:order][:bag_count]&.to_i || 1
        
        # Calculate pricing
        subtotal = bag_count * 2000  # $20 per bag in cents
        tax = (subtotal * 0.05).to_i  # 5% tax
        total = subtotal + tax
        
        order = current_user.orders.create!(
          address_id: params[:order][:address_id],
          pickup_date: pickup_date,
          pickup_time_window_id: params[:order][:pickup_time_window_id],
          delivery_date: delivery_date,
          delivery_time_window_id: params[:order][:pickup_time_window_id], # Use same for now
          order_type: params[:order][:order_type] || 'subscription',
          special_instructions: params[:order][:special_instructions],
          bag_count: bag_count,
          status: :scheduled,
          subtotal_cents: subtotal,
          tax_cents: tax,
          total_cents: total
        )
        
        # Reload to ensure associations are loaded
        order.reload
        
        render json: {
          order: order_json_detailed(order),
          message: "Your pickup has been scheduled successfully!"
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue => e
        puts "❌ Order creation error: #{e.message}"
        puts e.backtrace.first(5)
        render json: { error: e.message }, status: :unprocessable_entity
      end
      
      # PATCH /api/v1/orders/:id
      def update
        order = current_user.orders.find(params[:id])
        
        unless order.status == "scheduled"
          render json: { error: "This order cannot be modified" }, status: :unprocessable_entity
          return
        end
        
        if order.pickup_date < Date.tomorrow
          render json: {
            error: "Orders must be modified at least 24 hours before pickup"
          }, status: :unprocessable_entity
          return
        end
        
        if order.update(order_update_params)
          order.reload
          render json: {
            order: order_json_detailed(order),
            message: "Your order has been updated successfully"
          }
        else
          render json: {
            errors: order.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # POST /api/v1/orders/:id/cancel
      def cancel
        order = current_user.orders.find(params[:id])
        
        unless order.status == "scheduled"
          render json: { error: "This order cannot be cancelled" }, status: :unprocessable_entity
          return
        end
        
        order.update!(status: :canceled)
        render json: {
          order: order_json(order),
          message: "Your order has been cancelled successfully"
        }
      end
      
      # GET /api/v1/orders/:id/timeline
      def timeline
        order = current_user.orders.find(params[:id])
        render json: { timeline: [] }
      end
      
      # POST /api/v1/orders/:id/report-issue
      def report_issue
        render json: { message: "Issue reported successfully" }
      end
      
      private
      
      def order_update_params
        params.require(:order).permit(
          :pickup_date,
          :pickup_time_window_id,
          :special_instructions,
          :bag_count
        )
      end
      
      def order_json(order)
        {
          id: order.id,
          order_number: order.order_number || rand(1000..9999),
          user_id: order.user_id,
          status: order.status,
          order_type: order.order_type,
          pickup_date: order.pickup_date.to_s,
          delivery_date: order.delivery_date&.to_s,
          bag_count: order.bag_count,
          subtotal_cents: order.subtotal_cents || 0,
          tax_cents: order.tax_cents || 0,
          total_cents: order.total_cents || 0,
          special_instructions: order.special_instructions,
          created_at: order.created_at.iso8601,
          updated_at: order.updated_at.iso8601,
          pickup_time_window: order.pickup_time_window ? time_window_json(order.pickup_time_window) : nil
        }
      end
      
      def order_json_detailed(order)
        base = order_json(order)
        base.merge(
          address: order.address ? address_json(order.address) : nil,
          delivery_time_window: order.delivery_time_window ? time_window_json(order.delivery_time_window) : nil,
          pickup_actual_time: order.pickup_actual_time&.iso8601,
          delivery_actual_time: order.delivery_actual_time&.iso8601
        )
      end
      
      def address_json(address)
        {
          id: address.id,
          label: address.label,
          street_address: address.street_address,
          unit: address.unit,
          city: address.city,
          state: address.state,
          zip_code: address.zip_code,
          delivery_instructions: address.delivery_instructions
        }
      end
      
      def time_window_json(time_window)
        {
          id: time_window.id,
          label: time_window.label,
          start_time: format_time(time_window.start_time),
          end_time: format_time(time_window.end_time)
        }
      end
      
      def format_time(time)
        return nil unless time
        time.strftime('%I:%M %p')
      rescue
        time.to_s
      end
    end
  end
end
