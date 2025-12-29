# app/models/notification.rb

class Notification < ApplicationRecord
  belongs_to :user

  # Enums
  enum notification_type: {
    order_update: 0,
    subscription_renewal: 1,
    issue_update: 2,
    promotional: 3
  }

  validates :notification_type, presence: true
  validates :title, presence: true
  validates :body, presence: true
  validates :sent_at, presence: true

  scope :unread, -> { where(is_read: false) }
  scope :recent, -> { order(sent_at: :desc).limit(50) }

  def mark_as_read!
    update!(is_read: true, read_at: Time.current)
  end
end
