class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :subscription_plan
  belongs_to :recurring_time_window, class_name: 'TimeWindow', foreign_key: 'recurring_time_window_id', optional: true
  has_many :invoices
  
  # Status is stored as integer enum in database
  enum status: { active: 0, paused: 1, canceled: 2 }
  
  validates :status, presence: true
  
  def bags_remaining
    subscription_plan.bags_per_month - bags_used_this_period
  end
  
  def days_until_renewal
    return 0 unless current_period_end
    (current_period_end - Date.today).to_i
  end
  
  def auto_recurring_data
    return nil unless auto_recurring
    {
      enabled: true,
      day_of_week: recurring_day_name,
      time_window: recurring_time_window&.label
    }
  end
  
  def recurring_day_name
    return nil unless recurring_day
    Date::DAYNAMES[recurring_day]
  end
  
  def as_json(options = {})
    {
      id: id,
      user_id: user_id,
      plan: subscription_plan.as_json,
      status: status,
      bags_used_this_period: bags_used_this_period,
      bags_remaining: bags_remaining,
      current_period_end: current_period_end&.to_s,
      days_until_renewal: days_until_renewal,
      auto_recurring: auto_recurring_data
    }
  end
end
