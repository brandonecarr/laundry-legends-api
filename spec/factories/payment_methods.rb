FactoryBot.define do
  factory :payment_method do
    user { nil }
    stripe_payment_method_id { "MyString" }
    payment_type { 1 }
    last_four { "MyString" }
    brand { "MyString" }
    is_default { false }
  end
end
