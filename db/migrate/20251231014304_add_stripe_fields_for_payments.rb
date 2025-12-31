class AddStripeFieldsForPayments < ActiveRecord::Migration[7.1]
  def change
    # Add Stripe customer ID to users
    add_column :users, :stripe_customer_id, :string
    add_index :users, :stripe_customer_id, unique: true

    # Add missing card fields to payment_methods
    add_column :payment_methods, :expiry_month, :integer
    add_column :payment_methods, :expiry_year, :integer
    add_column :payment_methods, :funding, :string

    # Change payment_type from integer to string for flexibility
    change_column :payment_methods, :payment_type, :string
  end
end
