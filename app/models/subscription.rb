# app/models/subscription.rb

class Subscription < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :subscription_plan
  belongs_to :recurring_time_window, class_name: 'TimeWindow', foreign_key: 'recurring_time_window_id', optional: true
  
  # Enums
  enum status: {
    active: 0,
    paused: 1,
    canceled: 2
  }
  
  # Validations
  validates :status, presence: true
  validates :bags_used_this_period, numericality: { greater_than_or_equal_to: 0 }
  
  # Callbacks
  before_validation :set_period_dates, on: :create
  
  # Instance methods
  def bags_remaining
    subscription_plan.bags_per_month - bags_used_this_period
  end
  
  def has_bags_available?
    bags_remaining > 0
  end
  
  def price_in_dollars
    subscription_plan.price_cents / 100.0
  end
  
  def reset_period!
    update!(
      bags_used_this_period: 0,
      current_period_start: Date.today,
      current_period_end: Date.today + 1.month
    )
  end
  
  def period_ends_in_days
    return 0 if current_period_end < Date.today
    (current_period_end - Date.today).to_i
  end
  
  def usage_percentage
    return 0 if subscription_plan.bags_per_month.zero?
    ((bags_used_this_period.to_f / subscription_plan.bags_per_month) * 100).round
  end
  
  private
  
  def set_period_dates
    self.current_period_start ||= Date.today
    self.current_period_end ||= Date.today + 1.month
    self.bags_used_this_period ||= 0
  end
end
