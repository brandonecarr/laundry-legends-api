FactoryBot.define do
  factory :order do
    user { nil }
    address { nil }
    order_number { 1 }
    status { 1 }
    order_type { 1 }
    pickup_date { "2025-12-28" }
    pickup_time_window_id { "" }
    delivery_date { "2025-12-28" }
    delivery_time_window_id { "" }
    pickup_actual_time { "2025-12-28 14:11:29" }
    delivery_actual_time { "2025-12-28 14:11:29" }
    bag_count { 1 }
    subtotal_cents { 1 }
    tax_cents { 1 }
    total_cents { 1 }
    laundry_preferences_snapshot { "" }
    special_instructions { "MyText" }
  end
end
