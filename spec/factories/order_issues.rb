FactoryBot.define do
  factory :order_issue do
    order { nil }
    user { nil }
    issue_type { 1 }
    description { "MyText" }
    status { 1 }
    resolution_notes { "MyText" }
    resolved_at { "2025-12-28 14:11:36" }
    resolved_by_id { "" }
  end
end
