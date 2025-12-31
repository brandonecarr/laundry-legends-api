class AddStripeFieldsToSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    add_column :subscription_plans, :stripe_product_id, :string
    add_column :subscription_plans, :stripe_price_id, :string
  end
end
