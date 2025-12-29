class CreateAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table :addresses, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :label, null: false
      t.string :street_address, null: false
      t.string :unit
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip_code, null: false
      t.text :delivery_instructions
      t.boolean :is_default, default: false

      t.timestamps
    end

    # REMOVED: add_index :addresses, :user_id (already created by t.references)
    add_index :addresses, [:user_id, :is_default]
  end
end
