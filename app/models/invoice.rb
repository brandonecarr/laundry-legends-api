class Invoice < ApplicationRecord
  belongs_to :user
  belongs_to :subscription, optional: true
  belongs_to :order, optional: true
  
  validates :status, presence: true
  validates :amount_cents, :total_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  before_create :generate_invoice_number
  
  def as_json(options = {})
    {
      id: id,
      subscription_id: subscription_id,
      order_id: order_id,
      amount_cents: amount_cents,
      tax_cents: tax_cents,
      total_cents: total_cents,
      status: status,
      paid_at: paid_at,
      due_date: due_date,
      invoice_number: invoice_number,
      description: description,
      created_at: created_at
    }
  end
  
  private
  
  def generate_invoice_number
    self.invoice_number = "INV-#{Date.today.year}-#{format('%06d', Invoice.count + 1)}"
  end
end
