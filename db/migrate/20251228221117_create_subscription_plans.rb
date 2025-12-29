# db/migrate/XXXXXXXXXX_create_subscription_plans.rb
class CreateSubscriptionPlans < ActiveRecord::Migration[7.1]
  def change
    create_table :subscription_plans, id: :uuid do |t|
      t.string :name, null: false
      t.integer :bags_per_month, null: false
      t.integer :price_cents, null: false
      t.text :description
      t.boolean :is_active, default: true
      
      t.timestamps
    end
    
    add_index :subscription_plans, :is_active
  end
end
