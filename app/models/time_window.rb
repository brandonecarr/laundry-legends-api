# app/models/time_window.rb

class TimeWindow < ApplicationRecord
  has_many :subscriptions, foreign_key: :recurring_time_window_id

  validates :label, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true

  scope :active, -> { where(is_active: true) }
end
