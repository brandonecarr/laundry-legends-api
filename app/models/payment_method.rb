class PaymentMethod < ApplicationRecord
  belongs_to :user
  
  validates :stripe_payment_method_id, presence: true, uniqueness: true
  validates :type, presence: true
  
  before_save :ensure_single_default, if: :is_default?
  
  def as_json(options = {})
    {
      id: id,
      user_id: user_id,
      type: type,
      card: card_brand.present? ? {
        brand: card_brand,
        last4: card_last4,
        expiry_month: card_expiry_month,
        expiry_year: card_expiry_year,
        funding: card_funding
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
