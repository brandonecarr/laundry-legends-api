# db/migrate/XXXXXXXXXX_create_subscriptions.rb
class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :subscription_plan, null: false, foreign_key: true, type: :uuid
      t.string :stripe_subscription_id
      t.string :status, null: false
      t.integer :bags_used_this_period, default: 0
      t.date :current_period_end
      t.boolean :auto_recurring_enabled, default: false
      t.string :auto_recurring_day_of_week
      t.string :auto_recurring_time_window
      
      t.timestamps
    end
    
    add_index :subscriptions, :stripe_subscription_id, unique: true
    add_index :subscriptions, [:user_id, :status]
  end
end
