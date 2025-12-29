# app/models/order.rb

class Order < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :address
  belongs_to :pickup_time_window, class_name: 'TimeWindow', foreign_key: 'pickup_time_window_id'
  belongs_to :delivery_time_window, class_name: 'TimeWindow', foreign_key: 'delivery_time_window_id', optional: true
  
  has_many :timeline_events, class_name: 'OrderTimelineEvent', dependent: :destroy
  has_one :issue, class_name: 'OrderIssue', dependent: :destroy
  
  # Enums
  enum status: {
    scheduled: 0,
    picked_up: 1,
    in_cleaning: 2,
    quality_check: 3,
    out_for_delivery: 4,
    delivered: 5,
    canceled: 6
  }
  
  enum order_type: {
    subscription: 0,
    one_time: 1
  }
  
  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :pickup_date, presence: true
  validates :delivery_date, presence: true
  validates :bag_count, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true
  validates :order_type, presence: true
  
  # Callbacks
  before_validation :ensure_order_number, on: :create
  after_create :create_initial_timeline_event
  
  # Scopes
  scope :active, -> { where.not(status: [:delivered, :canceled]) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_pickup_date, ->(date) { where(pickup_date: date) }
  
  # Instance methods
  def formatted_order_number
    "##{order_number}"
  end
  
  def total_in_dollars
    total_cents / 100.0
  end
  
  def subtotal_in_dollars
    subtotal_cents / 100.0
  end
  
  def tax_in_dollars
    tax_cents / 100.0
  end
  
  def is_cancelable?
    scheduled? && pickup_date >= Date.tomorrow
  end
  
  def estimated_completion_percentage
    case status
    when 'scheduled'
      0
    when 'picked_up'
      25
    when 'in_cleaning'
      50
    when 'quality_check'
      75
    when 'out_for_delivery'
      90
    when 'delivered'
      100
    else
      0
    end
  end
  
  def days_until_pickup
    return 0 if pickup_date < Date.today
    (pickup_date - Date.today).to_i
  end
  
  def days_until_delivery
    return 0 if delivery_date < Date.today
    (delivery_date - Date.today).to_i
  end
  
  private
  
  def ensure_order_number
    return if order_number.present?
    
    last_order = Order.order(order_number: :desc).first
    self.order_number = last_order ? last_order.order_number + 1 : 1001
  end
  
  def create_initial_timeline_event
    timeline_events.create!(
      event_type: :pickup_confirmed,
      timestamp: Time.current,
      notes: "Pickup scheduled for #{pickup_date.strftime('%B %d, %Y')}"
    )
  end
end
