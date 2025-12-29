module Api
  module V1
      class Api::V1::SubscriptionPlansController < ApplicationController
          before_action :authenticate_request
        # Remove the skip_before_action line entirely
        
        def index
          # ...
        end
      end
  end
end
