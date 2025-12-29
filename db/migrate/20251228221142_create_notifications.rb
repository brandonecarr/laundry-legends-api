class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :notification_type, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.boolean :is_read, default: false
      t.jsonb :data
      t.datetime :sent_at, null: false
      t.datetime :read_at

      t.timestamps
    end

    # REMOVED: add_index :notifications, :user_id (already exists)
    add_index :notifications, :is_read
    add_index :notifications, :sent_at
  end
end
