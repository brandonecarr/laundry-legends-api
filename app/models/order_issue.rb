# app/models/order_issue.rb

class OrderIssue < ApplicationRecord
  belongs_to :order
  belongs_to :user
  belongs_to :resolved_by, class_name: 'User', foreign_key: 'resolved_by_id', optional: true

  # Enums
  enum issue_type: {
    missing_item: 0,
    damaged: 1,
    not_clean: 2,
    wrong_items: 3,
    other: 4
  }

  enum status: { submitted: 0, under_review: 1, resolved: 2 }

  validates :issue_type, presence: true
  validates :description, presence: true
end
