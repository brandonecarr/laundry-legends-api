FactoryBot.define do
  factory :laundry_preference do
    user { nil }
    detergent_type { 1 }
    water_temperature { 1 }
    dry_method { 1 }
    separate_kids_clothing { false }
    sensitive_skin { false }
    remove_pet_hair { false }
    fold_only { false }
    personal_notes { "MyText" }
  end
end
