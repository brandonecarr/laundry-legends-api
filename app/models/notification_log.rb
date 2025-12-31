class NotificationLog < ApplicationRecord
  belongs_to :user
  belongs_to :order, optional: true

  validates :channel, presence: true, inclusion: { in: %w[push sms email] }
  validates :notification_type, presence: true
  validates :status, presence: true, inclusion: { in: %w[pending sent delivered failed] }

  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: 'failed') }
  scope :sent, -> { where(status: 'sent') }
end
