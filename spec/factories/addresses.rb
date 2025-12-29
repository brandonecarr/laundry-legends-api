FactoryBot.define do
  factory :address do
    user { nil }
    label { "MyString" }
    street_address { "MyString" }
    unit { "MyString" }
    city { "MyString" }
    state { "MyString" }
    zip_code { "MyString" }
    delivery_instructions { "MyText" }
    is_default { false }
  end
end
