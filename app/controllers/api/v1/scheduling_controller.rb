# app/controllers/api/v1/scheduling_controller.rb

module Api
  module V1
    class SchedulingController < ApplicationController
      before_action :authenticate_request
      
      # GET /api/v1/scheduling/available-dates
      def available_dates
        # Return next 30 days of available dates
        start_date = Date.tomorrow # Can't schedule for today
        end_date = start_date + 30.days
        
        available_dates = (start_date..end_date).select do |date|
          date_available?(date)
        end
        
        render json: {
          available_dates: available_dates.map { |d| d.iso8601 }
        }
      end
      
      # GET /api/v1/scheduling/available-time-windows?date=YYYY-MM-DD
      def available_time_windows
        date_param = params[:date]
        
        unless date_param.present?
          render json: { error: "Date parameter is required" }, status: :bad_request
          return
        end
        
        begin
          date = Date.parse(date_param)
        rescue ArgumentError
          render json: { error: "Invalid date format. Use YYYY-MM-DD" }, status: :bad_request
          return
        end
        
        # Validate date is in the future
        if date < Date.tomorrow
          render json: { error: "Cannot schedule for past dates or today" }, status: :bad_request
          return
        end
        
        # Get all active time windows
        time_windows = TimeWindow.where(is_active: true).order(:start_time)
        
        # Check availability for each window
        available_windows = time_windows.map do |window|
          availability = check_time_window_availability(date, window.id)
          
          {
            id: window.id,
            label: window.label,
            start_time: window.start_time.strftime('%I:%M %p'),
            end_time: window.end_time.strftime('%I:%M %p'),
            available: availability[:available],
            spots_remaining: availability[:spots_remaining]
          }
        end
        
        render json: {
          date: date.iso8601,
          time_windows: available_windows
        }
      end
      
      private
      
      def date_available?(date)
        # Skip Sundays (adjust based on your business days)
        return false if date.sunday?
        
        # Could add holiday logic here
        # return false if Holiday.exists?(date: date)
        
        # Check if any time windows have availability
        TimeWindow.where(is_active: true).any? do |window|
          check_time_window_availability(date, window.id)[:available]
        end
      end
      
      def check_time_window_availability(date, time_window_id)
        # Count orders in this slot that are active (not cancelled or delivered)
        orders_count = Order.where(
          pickup_date: date,
          pickup_time_window_id: time_window_id,
          status: [:scheduled, :picked_up, :in_cleaning, :quality_check, :out_for_delivery]
        ).count
        
        # Maximum capacity per time slot (adjust based on your operations)
        max_capacity = 10
        
        spots_remaining = [max_capacity - orders_count, 0].max
        
        {
          available: spots_remaining > 0,
          spots_remaining: spots_remaining
        }
      end
    end
  end
end
