# db/migrate/XXXXXXXXXX_create_payment_methods.rb
class CreatePaymentMethods < ActiveRecord::Migration[7.1]
  def change
    create_table :payment_methods, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :stripe_payment_method_id, null: false
      t.string :type, null: false
      t.string :card_brand
      t.string :card_last4
      t.integer :card_expiry_month
      t.integer :card_expiry_year
      t.string :card_funding
      t.boolean :is_default, default: false
      
      t.timestamps
    end
    
    add_index :payment_methods, :stripe_payment_method_id, unique: true
    add_index :payment_methods, [:user_id, :is_default]
  end
end
