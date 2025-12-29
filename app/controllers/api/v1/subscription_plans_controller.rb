class Api::V1::SubscriptionPlansController < ApplicationController
  skip_before_action :authenticate_request  # Plans should be public anyway
  
  def index
    plans = SubscriptionPlan.where(is_active: true)
    render json: { plans: plans }
  end
end
