class CreateNotificationLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :notification_logs, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.uuid :order_id
      t.string :channel, null: false
      t.string :notification_type, null: false
      t.string :status, null: false
      t.text :message
      t.jsonb :metadata
      t.string :error_message

      t.timestamps
    end

    add_index :notification_logs, :user_id
    add_index :notification_logs, :order_id
    add_index :notification_logs, [:channel, :status]
    add_foreign_key :notification_logs, :users
    add_foreign_key :notification_logs, :orders
  end
end
