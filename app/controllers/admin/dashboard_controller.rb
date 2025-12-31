module Admin
  class DashboardController < BaseController
    def index
      @stats = {
        orders_today: Order.where(created_at: Date.today.all_day).count,
        pending_pickups: Order.where(status: :scheduled, pickup_date: Date.today).count,
        in_progress: Order.where(status: [:picked_up, :in_cleaning, :quality_check]).count,
        out_for_delivery: Order.where(status: :out_for_delivery).count,
        delivered_today: Order.where(status: :delivered).where('updated_at >= ?', Date.today.beginning_of_day).count,
        open_issues: OrderIssue.where(status: [:submitted, :under_review]).count,
        active_subscriptions: Subscription.where(status: :active).count,
        total_customers: User.where(role: :customer).count,
        revenue_today: Order.where(status: :delivered)
                            .where('updated_at >= ?', Date.today.beginning_of_day)
                            .sum(:total_cents) / 100.0,
        revenue_this_week: Order.where(status: :delivered)
                                .where('updated_at >= ?', Date.today.beginning_of_week)
                                .sum(:total_cents) / 100.0,
        revenue_this_month: Order.where(status: :delivered)
                                 .where('updated_at >= ?', Date.today.beginning_of_month)
                                 .sum(:total_cents) / 100.0
      }

      @recent_orders = Order.includes(:user, :address)
                            .order(created_at: :desc)
                            .limit(10)

      @recent_issues = OrderIssue.includes(:order, :user)
                                 .where(status: [:submitted, :under_review])
                                 .order(created_at: :desc)
                                 .limit(5)

      @todays_schedule = Order.includes(:user, :address, :pickup_time_window)
                              .where(pickup_date: Date.today)
                              .where.not(status: [:delivered, :canceled])
                              .order('time_windows.start_time')
    end
  end
end
