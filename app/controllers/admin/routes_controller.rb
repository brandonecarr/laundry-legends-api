module Admin
  class RoutesController < BaseController
    def index
      @date = params[:date] ? Date.parse(params[:date]) : Date.today
      @orders = Order.includes(:user, :address, :pickup_time_window)
                     .where(pickup_date: @date)
                     .where.not(status: [:delivered, :canceled])
                     .order('time_windows.start_time')
    end

    def optimize
      # TODO: Implement Mapbox route optimization
      flash[:notice] = 'Route optimization coming soon!'
      redirect_to admin_routes_path(date: params[:date])
    end
  end
end
