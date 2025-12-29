# app/models/payment_method.rb

class PaymentMethod < ApplicationRecord
  belongs_to :user

  # Enums
  enum payment_type: { card: 0, bank_account: 1 }

  validates :stripe_payment_method_id, presence: true, uniqueness: true
  validates :last_four, presence: true
  validates :payment_type, presence: true
end
