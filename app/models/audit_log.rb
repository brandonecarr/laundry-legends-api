class AuditLog < ApplicationRecord
  belongs_to :user, optional: true

  validates :action, presence: true

  ACTIONS = %w[
    login logout
    order_created order_updated order_status_changed order_canceled
    customer_updated
    issue_created issue_updated issue_resolved
    subscription_created subscription_updated subscription_canceled
    notification_sent
    settings_updated
    admin_login admin_logout
  ].freeze

  scope :recent, -> { order(created_at: :desc) }
  scope :by_action, ->(action) { where(action: action) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_resource, ->(type, id) { where(resource_type: type, resource_id: id) }
  scope :today, -> { where('created_at >= ?', Time.current.beginning_of_day) }
  scope :this_week, -> { where('created_at >= ?', 1.week.ago) }

  class << self
    def log(action:, user: nil, resource: nil, metadata: {}, request: nil)
      create!(
        action: action,
        user: user,
        resource_type: resource&.class&.name,
        resource_id: resource&.id,
        metadata: metadata,
        ip_address: request&.remote_ip,
        user_agent: request&.user_agent&.truncate(500)
      )
    rescue StandardError => e
      Rails.logger.error("Failed to create audit log: #{e.message}")
      nil
    end

    def log_admin_action(action:, admin:, resource: nil, metadata: {}, request: nil)
      log(
        action: action,
        user: admin,
        resource: resource,
        metadata: metadata.merge(admin_action: true),
        request: request
      )
    end
  end

  def resource
    return nil unless resource_type.present? && resource_id.present?
    resource_type.constantize.find_by(id: resource_id)
  rescue NameError
    nil
  end

  def action_description
    case action
    when 'login' then 'User logged in'
    when 'logout' then 'User logged out'
    when 'admin_login' then 'Admin logged in'
    when 'admin_logout' then 'Admin logged out'
    when 'order_created' then 'Order created'
    when 'order_updated' then 'Order updated'
    when 'order_status_changed' then "Order status changed to #{metadata['new_status']}"
    when 'order_canceled' then 'Order canceled'
    when 'customer_updated' then 'Customer profile updated'
    when 'issue_created' then 'Issue reported'
    when 'issue_updated' then 'Issue updated'
    when 'issue_resolved' then 'Issue resolved'
    when 'subscription_created' then 'Subscription created'
    when 'subscription_updated' then 'Subscription updated'
    when 'subscription_canceled' then 'Subscription canceled'
    when 'notification_sent' then "Notification sent: #{metadata['notification_type']}"
    when 'settings_updated' then 'Settings updated'
    else action.humanize
    end
  end
end
