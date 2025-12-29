# app/services/order_creation_service.rb

class OrderCreationService
  class << self
    def call(user:, params:)
      new(user, params).create_order
    end
  end

  def initialize(user, params)
    @user = user
    @address_id = params[:address_id]
    @pickup_date = params[:pickup_date]
    @pickup_time_window_id = params[:pickup_time_window_id]
    @order_type = params[:order_type] || 'subscription'
    @special_instructions = params[:special_instructions]
    @bag_count = params[:bag_count] || 1
  end

  def create_order
    validate_inputs!
    
    ActiveRecord::Base.transaction do
      @order = Order.create!(order_attributes)
      
      # Update subscription if this is a subscription order
      update_subscription_usage if subscription_order?
      
      # Create initial timeline event
      create_initial_timeline_event
      
      # Snapshot laundry preferences
      snapshot_preferences
      
      @order
    end
  rescue ActiveRecord::RecordInvalid => e
    # Return order with errors
    Order.new.tap { |o| o.errors.add(:base, e.message) }
  rescue StandardError => e
    Rails.logger.error "Order creation failed: #{e.message}"
    Order.new.tap { |o| o.errors.add(:base, "Order creation failed: #{e.message}") }
  end

  private

  def validate_inputs!
    raise "Address is required" unless @address_id.present?
    raise "Pickup date is required" unless @pickup_date.present?
    raise "Pickup time window is required" unless @pickup_time_window_id.present?
    
    # Validate address belongs to user
    address = @user.addresses.find_by(id: @address_id)
    raise "Invalid address" unless address.present?
    
    # Validate time window exists and is active
    time_window = TimeWindow.find_by(id: @pickup_time_window_id, is_active: true)
    raise "Invalid time window" unless time_window.present?
    
    # Validate pickup date is in the future
    pickup_date = Date.parse(@pickup_date.to_s)
    raise "Pickup date must be in the future" if pickup_date < Date.today
    
    # Check scheduling availability
    if slot_fully_booked?(pickup_date, @pickup_time_window_id)
      raise "This time slot is fully booked. Please select another time."
    end
    
    # Validate subscription if subscription order
    if subscription_order?
      validate_subscription!
    end
  end

  def validate_subscription!
    subscription = @user.subscription
    
    raise "No active subscription found" unless subscription&.active?
    
    # Check if user has bags remaining
    bags_remaining = subscription.bags_remaining
    raise "No bags remaining in your subscription for this period" if bags_remaining <= 0
  end

  def slot_fully_booked?(date, time_window_id)
    # Check how many orders are already scheduled for this slot
    orders_count = Order.where(
      pickup_date: date,
      pickup_time_window_id: time_window_id,
      status: [:scheduled, :picked_up, :in_cleaning, :quality_check, :out_for_delivery]
    ).count
    
    # Maximum orders per slot (adjust this based on capacity)
    max_orders_per_slot = 10
    
    orders_count >= max_orders_per_slot
  end

  def order_attributes
    delivery_date = calculate_delivery_date
    pricing = calculate_pricing
    
    {
      user_id: @user.id,
      address_id: @address_id,
      order_number: generate_order_number,
      status: :scheduled,
      order_type: @order_type,
      pickup_date: @pickup_date,
      pickup_time_window_id: @pickup_time_window_id,
      delivery_date: delivery_date,
      delivery_time_window_id: @pickup_time_window_id, # Same time window for delivery
      bag_count: @bag_count,
      subtotal_cents: pricing[:subtotal_cents],
      tax_cents: pricing[:tax_cents],
      total_cents: pricing[:total_cents],
      special_instructions: @special_instructions
    }
  end

  def generate_order_number
    # Get the last order number and increment
    last_order = Order.order(order_number: :desc).first
    last_order ? last_order.order_number + 1 : 1001
  end

  def calculate_delivery_date
    # Standard turnaround: pick up today, deliver in 2 days
    pickup = Date.parse(@pickup_date.to_s)
    pickup + 2.days
  end

  def calculate_pricing
    if subscription_order?
      # Subscription orders are already paid for
      {
        subtotal_cents: 0,
        tax_cents: 0,
        total_cents: 0
      }
    else
      # One-time order pricing
      # $25 per bag + tax
      price_per_bag = 2500 # $25.00 in cents
      subtotal = price_per_bag * @bag_count
      tax = (subtotal * 0.0725).to_i # 7.25% tax rate (adjust for your location)
      
      {
        subtotal_cents: subtotal,
        tax_cents: tax,
        total_cents: subtotal + tax
      }
    end
  end

  def subscription_order?
    @order_type.to_s == 'subscription'
  end

  def update_subscription_usage
    subscription = @user.subscription
    return unless subscription
    
    subscription.increment!(:bags_used_this_period, @bag_count)
  end

  def create_initial_timeline_event
    @order.timeline_events.create!(
      event_type: :pickup_confirmed,
      timestamp: Time.current,
      notes: "Your pickup has been scheduled for #{@order.pickup_date.strftime('%B %d, %Y')}"
    )
  end

  def snapshot_preferences
    # Save user's laundry preferences at time of order
    if @user.laundry_preference
      @order.update!(
        laundry_preferences_snapshot: @user.laundry_preference.as_json(
          except: [:id, :user_id, :created_at, :updated_at]
        )
      )
    end
  end
end
