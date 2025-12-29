FactoryBot.define do
  factory :subscription do
    user { nil }
    subscription_plan { nil }
    status { 1 }
    bags_used_this_period { 1 }
    current_period_start { "2025-12-28" }
    current_period_end { "2025-12-28" }
    auto_recurring { false }
    recurring_day { 1 }
    recurring_time_window_id { "" }
    stripe_subscription_id { "MyString" }
  end
end
