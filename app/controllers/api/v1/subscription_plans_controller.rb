module Api
  module V1
    class SubscriptionPlansController < ApplicationController
      skip_before_action :authenticate_user!, only: [:index]
      
      def index
        plans = SubscriptionPlan.active.order(:price_cents)
        render json: { plans: plans }
      end
    end
  end
end
