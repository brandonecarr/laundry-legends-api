class CreatePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_methods, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :stripe_payment_method_id, null: false
      t.integer :payment_type, null: false
      t.string :last_four, null: false
      t.string :brand
      t.boolean :is_default, default: false

      t.timestamps
    end

    # REMOVED: add_index :payment_methods, :user_id (already exists)
    add_index :payment_methods, :stripe_payment_method_id, unique: true
    add_index :payment_methods, [:user_id, :is_default]
  end
end
