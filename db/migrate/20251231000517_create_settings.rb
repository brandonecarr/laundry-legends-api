class CreateSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :description
      t.string :setting_type, default: 'string'

      t.timestamps
    end

    add_index :settings, :key, unique: true
  end
end
