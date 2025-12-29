FactoryBot.define do
  factory :time_window do
    label { "MyString" }
    start_time { "2025-12-28 14:11:25" }
    end_time { "2025-12-28 14:11:25" }
    is_active { false }
  end
end
