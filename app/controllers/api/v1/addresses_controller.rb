# app/controllers/api/v1/addresses_controller.rb

module Api
  module V1
    class AddressesController < ApplicationController
      before_action :set_address, only: [:show, :update, :destroy]
      
      # GET /api/v1/user/addresses
      def index
        addresses = current_user.addresses.order(created_at: :desc)
        
        render json: {
          addresses: addresses.map { |a| address_response(a) }
        }
      end
      
      # GET /api/v1/user/addresses/:id
      def show
        render json: {
          address: address_response(@address)
        }
      end
      
      # POST /api/v1/user/addresses
      def create
        # If this is the first address, make it default
        is_first = current_user.addresses.empty?
        
        address = current_user.addresses.new(address_params)
        address.is_default = true if is_first
        
        # If setting as default, unset other defaults
        if address.is_default
          current_user.addresses.where(is_default: true).update_all(is_default: false)
        end
        
        if address.save
          render json: {
            address: address_response(address)
          }, status: :created
        else
          render json: { errors: address.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # PATCH /api/v1/user/addresses/:id
      def update
        # If setting as default, unset other defaults
        if params[:is_default] == true || params[:is_default] == 'true'
          current_user.addresses.where(is_default: true).update_all(is_default: false)
        end
        
        if @address.update(address_params)
          render json: {
            address: address_response(@address)
          }
        else
          render json: { errors: @address.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      # DELETE /api/v1/user/addresses/:id
      def destroy
        @address.destroy
        render json: { message: 'Address deleted successfully' }
      end
      
      private
      
      def set_address
        @address = current_user.addresses.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Address not found' }, status: :not_found
      end
      
      def address_params
        params.permit(
          :label, :street_address, :unit, :city, :state, :zip_code,
          :delivery_instructions, :is_default
        )
      end
      
      def address_response(address)
        {
          id: address.id,
          user_id: address.user_id,
          label: address.label,
          street_address: address.street_address,
          unit: address.unit,
          city: address.city,
          state: address.state,
          zip_code: address.zip_code,
          delivery_instructions: address.delivery_instructions,
          is_default: address.is_default,
          formatted_address: address.formatted_address,
          short_address: address.short_address
        }
      end
    end
  end
end
