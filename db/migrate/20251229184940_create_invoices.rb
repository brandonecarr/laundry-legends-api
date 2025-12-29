# db/migrate/XXXXXXXXXX_create_invoices.rb
class CreateInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :invoices, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :subscription, foreign_key: true, type: :uuid
      t.references :order, foreign_key: true, type: :uuid
      t.string :stripe_invoice_id
      t.string :invoice_number
      t.integer :amount_cents, null: false
      t.integer :tax_cents, default: 0
      t.integer :total_cents, null: false
      t.string :status, null: false
      t.text :description
      t.datetime :paid_at
      t.date :due_date
      
      t.timestamps
    end
    
    add_index :invoices, :stripe_invoice_id, unique: true
    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, [:user_id, :status]
  end
end
