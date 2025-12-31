# app/models/user.rb

class User < ApplicationRecord
  has_secure_password

  # Enums
  enum role: { customer: 0, admin: 1, driver: 2 }

  # Associations
  has_many :addresses, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :payment_methods, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :device_tokens, dependent: :destroy
  has_many :notification_logs, dependent: :destroy
  has_one :laundry_preference, dependent: :destroy
  has_one :subscription, dependent: :destroy


  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :password, length: { minimum: 6 }, if: -> { password.present? }

  # Callbacks
  after_create :create_default_preference

  # Instance Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  # Stripe Methods
  def get_or_create_stripe_customer
    return stripe_customer_id if stripe_customer_id.present?

    customer = Stripe::Customer.create(
      email: email,
      name: full_name,
      metadata: { user_id: id }
    )

    update!(stripe_customer_id: customer.id)
    customer.id
  end

  def stripe_customer
    return nil unless stripe_customer_id.present?
    Stripe::Customer.retrieve(stripe_customer_id)
  rescue Stripe::InvalidRequestError
    nil
  end

  def default_payment_method
    payment_methods.find_by(is_default: true) || payment_methods.first
  end

  private

  def create_default_preference
    create_laundry_preference!(
      detergent_type: :standard,
      water_temperature: :warm,
      dry_method: :machine
    )
  end
end
