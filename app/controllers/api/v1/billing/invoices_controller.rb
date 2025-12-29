module Api
  module V1
    module Billing
      class InvoicesController < ApplicationController
        before_action :authenticate_user!
        before_action :set_invoice, only: [:show]
        
        def index
          invoices = current_user.invoices.order(created_at: :desc)
          render json: { invoices: invoices }
        end
        
        def show
          render json: { invoice: @invoice }
        end
        
        private
        
        def set_invoice
          @invoice = current_user.invoices.find(params[:id])
        end
      end
    end
  end
end
