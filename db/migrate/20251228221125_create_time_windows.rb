class CreateTimeWindows < ActiveRecord::Migration[7.1]
  def change
    create_table :time_windows, id: :uuid do |t|
      t.string :label, null: false
      t.time :start_time, null: false
      t.time :end_time, null: false
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :time_windows, :is_active
  end
end
