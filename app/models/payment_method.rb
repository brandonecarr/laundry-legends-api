class PaymentMethod < ApplicationRecord
  belongs_to :user

  validates :stripe_payment_method_id, presence: true, uniqueness: true
  validates :payment_type, presence: true

  before_save :ensure_single_default, if: :is_default?

  def as_json(options = {})
    {
      id: id,
      user_id: user_id,
      type: payment_type,  # Maps to iOS 'type' field
      card: payment_type == 'card' ? {
        brand: brand,
        last4: last_four,
        expiry_month: expiry_month,
        expiry_year: expiry_year,
        funding: funding
      } : nil,
      is_default: is_default,
      created_at: created_at
    }
  end

  private

  def ensure_single_default
    PaymentMethod.where(user: user).where.not(id: id).update_all(is_default: false)
  end
end
