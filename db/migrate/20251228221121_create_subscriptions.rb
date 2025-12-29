class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.references :subscription_plan, null: false, foreign_key: true, type: :uuid
      t.integer :status, default: 0, null: false
      t.integer :bags_used_this_period, default: 0
      t.date :current_period_start
      t.date :current_period_end
      t.boolean :auto_recurring, default: false
      t.integer :recurring_day
      t.uuid :recurring_time_window_id
      t.string :stripe_subscription_id

      t.timestamps
    end

    add_index :subscriptions, :status
    add_index :subscriptions, :stripe_subscription_id, unique: true
  end
end
