FactoryBot.define do
  factory :order_timeline_event do
    order { nil }
    event_type { 1 }
    timestamp { "2025-12-28 14:11:32" }
    notes { "MyText" }
    created_by_id { "" }
  end
end
