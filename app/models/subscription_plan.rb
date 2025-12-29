class SubscriptionPlan < ApplicationRecord
  has_many :subscriptions
  
  validates :name, presence: true
  validates :bags_per_month, presence: true, numericality: { greater_than: 0 }
  validates :price_cents, presence: true, numericality: { greater_than: 0 }
  
  scope :active, -> { where(is_active: true) }
  
  def formatted_price
    "$#{'%.2f' % (price_cents / 100.0)}"
  end
end
