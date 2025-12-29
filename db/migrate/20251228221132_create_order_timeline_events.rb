class CreateOrderTimelineEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :order_timeline_events, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid
      t.integer :event_type, null: false
      t.datetime :timestamp, null: false
      t.text :notes
      t.uuid :created_by_id

      t.timestamps
    end

    # REMOVED: add_index :order_timeline_events, :order_id (already exists)
    add_index :order_timeline_events, :event_type
    add_index :order_timeline_events, :timestamp
  end
end
