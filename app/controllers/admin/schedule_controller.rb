module Admin
  class ScheduleController < BaseController
    def index
      @date = params[:date] ? Date.parse(params[:date]) : Date.today
      @week_start = @date.beginning_of_week
      @week_end = @date.end_of_week

      @weekly_orders = Order.includes(:user, :address, :pickup_time_window)
                            .where(pickup_date: @week_start..@week_end)
                            .where.not(status: [:delivered, :canceled])
                            .order(:pickup_date, 'time_windows.start_time')

      @orders_by_date = @weekly_orders.group_by(&:pickup_date)
    end

    def day
      @date = Date.parse(params[:date])
      @time_windows = TimeWindow.order(:start_time)

      @orders = Order.includes(:user, :address, :pickup_time_window, :delivery_time_window)
                     .where(pickup_date: @date)
                     .where.not(status: [:delivered, :canceled])
                     .order('time_windows.start_time')

      @orders_by_window = @orders.group_by(&:pickup_time_window_id)

      if params[:optimize] == 'true' && @orders.any?
        @route_result = RouteOptimizationService.new(orders: @orders.to_a).optimize
        if @route_result[:success]
          @optimized_orders = @route_result[:optimized_orders]
          @route_stats = {
            duration: @route_result[:total_duration_minutes],
            distance: @route_result[:total_distance_miles]
          }
        end
      end
    end

    def optimize_route
      @date = Date.parse(params[:date])
      time_window_id = params[:time_window_id]

      orders = Order.includes(:user, :address)
                    .where(pickup_date: @date)
                    .where.not(status: [:delivered, :canceled])

      orders = orders.where(pickup_time_window_id: time_window_id) if time_window_id.present?

      if orders.empty?
        render json: { success: false, error: 'No orders to optimize' }
        return
      end

      result = RouteOptimizationService.new(orders: orders.to_a).optimize

      if result[:success]
        render json: {
          success: true,
          optimized_orders: result[:optimized_orders].map do |order|
            {
              id: order.id,
              order_number: order.formatted_order_number,
              customer_name: order.user.full_name,
              address: order.address ? "#{order.address.street_address}, #{order.address.city}" : 'No address'
            }
          end,
          total_duration_minutes: result[:total_duration_minutes],
          total_distance_miles: result[:total_distance_miles],
          geometry: result[:geometry]
        }
      else
        render json: { success: false, error: result[:error] }
      end
    end
  end
end
