# app/models/subscription_plan.rb

class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions

  validates :name, presence: true
  validates :bags_per_month, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(is_active: true) }

  def formatted_price
    dollars = price_cents / 100.0
    format("$%.2f", dollars)
  end
end
