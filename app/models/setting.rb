class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true
  validates :setting_type, inclusion: { in: %w[string integer boolean json] }

  DEFAULTS = {
    'facility_name' => { value: 'Laundry Legends', type: 'string', description: 'Business name' },
    'facility_address' => { value: '', type: 'string', description: 'Facility street address' },
    'facility_city' => { value: '', type: 'string', description: 'Facility city' },
    'facility_state' => { value: '', type: 'string', description: 'Facility state' },
    'facility_zip' => { value: '', type: 'string', description: 'Facility ZIP code' },
    'facility_latitude' => { value: '33.7490', type: 'string', description: 'Facility latitude for route optimization' },
    'facility_longitude' => { value: '-84.3880', type: 'string', description: 'Facility longitude for route optimization' },
    'business_phone' => { value: '', type: 'string', description: 'Business phone number' },
    'business_email' => { value: '', type: 'string', description: 'Business email address' },
    'notifications_enabled' => { value: 'true', type: 'boolean', description: 'Enable push/SMS notifications' },
    'auto_notify_on_status_change' => { value: 'true', type: 'boolean', description: 'Auto-send notifications on status changes' },
    'max_bags_per_order' => { value: '10', type: 'integer', description: 'Maximum bags allowed per order' },
    'price_per_bag_cents' => { value: '2500', type: 'integer', description: 'Price per bag in cents' },
    'tax_rate' => { value: '0.08', type: 'string', description: 'Tax rate (e.g., 0.08 for 8%)' },
    'min_hours_before_pickup' => { value: '24', type: 'integer', description: 'Minimum hours notice for pickup scheduling' },
    'max_days_advance_booking' => { value: '14', type: 'integer', description: 'Maximum days in advance for booking' }
  }.freeze

  class << self
    def get(key)
      setting = find_by(key: key)
      return cast_value(setting.value, setting.setting_type) if setting

      default = DEFAULTS[key.to_s]
      default ? cast_value(default[:value], default[:type]) : nil
    end

    def set(key, value)
      setting = find_or_initialize_by(key: key)
      default = DEFAULTS[key.to_s]

      setting.value = value.to_s
      setting.setting_type = default&.dig(:type) || 'string'
      setting.description = default&.dig(:description)
      setting.save!
      setting
    end

    def all_with_defaults
      result = {}

      DEFAULTS.each do |key, config|
        setting = find_by(key: key)
        result[key] = {
          value: setting ? cast_value(setting.value, setting.setting_type) : cast_value(config[:value], config[:type]),
          type: config[:type],
          description: config[:description]
        }
      end

      result
    end

    def seed_defaults!
      DEFAULTS.each do |key, config|
        find_or_create_by!(key: key) do |setting|
          setting.value = config[:value]
          setting.setting_type = config[:type]
          setting.description = config[:description]
        end
      end
    end

    private

    def cast_value(value, type)
      case type
      when 'integer'
        value.to_i
      when 'boolean'
        value.to_s.downcase == 'true'
      when 'json'
        JSON.parse(value) rescue {}
      else
        value
      end
    end
  end
end
