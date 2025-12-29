class CreateOrderIssues < ActiveRecord::Migration[7.1]
  def change
    create_table :order_issues, id: :uuid do |t|
      t.references :order, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :issue_type, null: false
      t.text :description, null: false
      t.integer :status, default: 0, null: false
      t.text :resolution_notes
      t.datetime :resolved_at
      t.uuid :resolved_by_id

      t.timestamps
    end

    add_index :order_issues, :status
  end
end
