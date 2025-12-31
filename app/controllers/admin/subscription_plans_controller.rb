module Admin
  class SubscriptionPlansController < BaseController
    before_action :set_subscription_plan, only: [:show, :edit, :update, :destroy]

    def index
      @subscription_plans = SubscriptionPlan.all.order(:price_cents)
    end

    def show
      @active_subscribers = Subscription.where(subscription_plan: @subscription_plan, status: :active).count
      @subscribers = Subscription.includes(:user)
                                  .where(subscription_plan: @subscription_plan)
                                  .order(created_at: :desc)
                                  .limit(20)
    end

    def new
      @subscription_plan = SubscriptionPlan.new
    end

    def create
      @subscription_plan = SubscriptionPlan.new(subscription_plan_params)

      if @subscription_plan.save
        flash[:notice] = 'Subscription plan created successfully.'
        redirect_to admin_subscription_plans_path
      else
        flash.now[:alert] = 'Failed to create subscription plan.'
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @subscription_plan.update(subscription_plan_params)
        flash[:notice] = 'Subscription plan updated successfully.'
        redirect_to admin_subscription_plan_path(@subscription_plan)
      else
        flash.now[:alert] = 'Failed to update subscription plan.'
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      active_subscriptions = Subscription.where(subscription_plan: @subscription_plan, status: :active).count

      if active_subscriptions > 0
        flash[:alert] = "Cannot delete plan with #{active_subscriptions} active subscriptions. Mark as inactive instead."
        redirect_to admin_subscription_plan_path(@subscription_plan)
      else
        @subscription_plan.destroy
        flash[:notice] = 'Subscription plan deleted successfully.'
        redirect_to admin_subscription_plans_path
      end
    end

    private

    def set_subscription_plan
      @subscription_plan = SubscriptionPlan.find(params[:id])
    end

    def subscription_plan_params
      params.require(:subscription_plan).permit(:name, :bags_per_month, :price_cents, :price_per_bag_cents, :description, :is_active)
    end
  end
end
