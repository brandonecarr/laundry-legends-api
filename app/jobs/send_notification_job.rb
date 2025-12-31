class SendNotificationJob < ApplicationJob
  queue_as :notifications

  def perform(user_id:, notification_type:, order_id: nil, channels: [:push, :sms], data: {})
    user = User.find_by(id: user_id)
    return unless user

    order = order_id ? Order.find_by(id: order_id) : nil

    service = NotificationService.new(
      user: user,
      notification_type: notification_type,
      order: order,
      data: data
    )

    case channels
    when [:push]
      service.send_push_only
    when [:sms]
      service.send_sms_only
    else
      service.send_all
    end
  end
end
