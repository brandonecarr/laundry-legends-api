# app/models/order_timeline_event.rb

class OrderTimelineEvent < ApplicationRecord
  belongs_to :order
  belongs_to :created_by, class_name: 'User', foreign_key: 'created_by_id', optional: true

  # Enums
  enum event_type: {
    pickup_confirmed: 0,
    in_cleaning: 1,
    quality_check: 2,
    out_for_delivery: 3,
    delivered: 4
  }

  validates :event_type, presence: true
  validates :timestamp, presence: true

  default_scope { order(timestamp: :asc) }
end
