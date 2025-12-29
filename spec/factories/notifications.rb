FactoryBot.define do
  factory :notification do
    user { nil }
    notification_type { 1 }
    title { "MyString" }
    body { "MyText" }
    is_read { false }
    data { "" }
    sent_at { "2025-12-28 14:11:42" }
    read_at { "2025-12-28 14:11:42" }
  end
end
