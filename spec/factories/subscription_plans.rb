FactoryBot.define do
  factory :subscription_plan do
    name { "MyString" }
    bags_per_month { 1 }
    price_cents { 1 }
    description { "MyText" }
    is_active { false }
  end
end
