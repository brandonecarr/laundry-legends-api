# app/models/laundry_preference.rb

class LaundryPreference < ApplicationRecord
  belongs_to :user

  # Enums
  enum detergent_type: { standard: 0, fragrance_free: 1, hypoallergenic: 2, eco: 3 }
  enum water_temperature: { hot: 0, warm: 1, cold: 2 }
  enum dry_method: { machine: 0, air_dry: 1, low_heat: 2 }
end
