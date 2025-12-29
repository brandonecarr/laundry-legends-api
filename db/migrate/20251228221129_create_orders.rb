class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :address, null: false, foreign_key: true, type: :uuid
      t.integer :order_number, null: false
      t.integer :status, default: 0, null: false
      t.integer :order_type, default: 0, null: false
      t.date :pickup_date, null: false
      t.uuid :pickup_time_window_id, null: false
      t.date :delivery_date
      t.uuid :delivery_time_window_id
      t.datetime :pickup_actual_time
      t.datetime :delivery_actual_time
      t.integer :bag_count
      t.integer :subtotal_cents
      t.integer :tax_cents
      t.integer :total_cents
      t.jsonb :laundry_preferences_snapshot
      t.text :special_instructions

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    # REMOVED: add_index :orders, :user_id (already exists from t.references)
    # REMOVED: add_index :orders, :address_id (already exists from t.references)
    add_index :orders, :status
    add_index :orders, :pickup_date
    add_index :orders, :order_type
  end
end
