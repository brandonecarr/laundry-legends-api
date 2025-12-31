module Admin
  class CustomersController < BaseController
    before_action :set_customer, only: [:show, :edit, :update]

    def index
      @customers = User.where(role: :customer)
                       .includes(:addresses, :subscription)
                       .order(created_at: :desc)

      if params[:search].present?
        search_term = "%#{params[:search].downcase}%"
        @customers = @customers.where(
          'LOWER(email) LIKE ? OR LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ? OR phone LIKE ?',
          search_term, search_term, search_term, "%#{params[:search]}%"
        )
      end

      if params[:has_subscription].present?
        if params[:has_subscription] == 'true'
          @customers = @customers.joins(:subscription).where(subscriptions: { status: :active })
        else
          @customers = @customers.left_joins(:subscription)
                                 .where(subscriptions: { id: nil })
                                 .or(@customers.left_joins(:subscription)
                                              .where.not(subscriptions: { status: :active }))
        end
      end

      @customers = @customers.page(params[:page]).per(25)
    end

    def show
      @orders = @customer.orders.includes(:address, :pickup_time_window)
                                .order(created_at: :desc)
                                .limit(20)
      @subscription = @customer.subscription
      @addresses = @customer.addresses
      @issues = OrderIssue.joins(:order).where(orders: { user_id: @customer.id }).limit(10)
      @total_spent = @customer.orders.where(status: :delivered).sum(:total_cents) / 100.0
      @total_orders = @customer.orders.count
    end

    def edit
    end

    def update
      if @customer.update(customer_params)
        flash[:notice] = 'Customer updated successfully.'
        redirect_to admin_customer_path(@customer)
      else
        flash.now[:alert] = 'Failed to update customer.'
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_customer
      @customer = User.find(params[:id])
    end

    def customer_params
      params.require(:user).permit(:first_name, :last_name, :email, :phone)
    end
  end
end
