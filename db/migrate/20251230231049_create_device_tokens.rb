class CreateDeviceTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :device_tokens, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :token, null: false
      t.string :platform, null: false
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :device_tokens, [:user_id, :platform]
    add_index :device_tokens, :token, unique: true
    add_foreign_key :device_tokens, :users
  end
end
