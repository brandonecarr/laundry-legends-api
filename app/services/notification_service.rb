class NotificationService
  NOTIFICATION_TEMPLATES = {
    on_way_pickup: {
      title: 'On Our Way!',
      push: "Hi {customer_name}! We're on our way to pick up your laundry (Order {order_number}). See you soon!",
      sms: "Laundry Legends: We're on our way to pick up your laundry (Order {order_number}). See you soon!"
    },
    picked_up: {
      title: 'Laundry Picked Up',
      push: "Your laundry has been picked up! We counted {bag_count} bags. It's now heading to our facility for cleaning.",
      sms: "Laundry Legends: Your laundry has been picked up ({bag_count} bags). Heading to our facility now!"
    },
    started_cleaning: {
      title: 'Cleaning Started',
      push: "Good news! We've started cleaning your laundry (Order {order_number}). We'll take great care of your items!",
      sms: "Laundry Legends: We've started cleaning your laundry (Order {order_number})."
    },
    cleaning_complete: {
      title: 'Cleaning Complete',
      push: "Your laundry is clean and fresh! We're now doing quality checks and packing everything up.",
      sms: "Laundry Legends: Your laundry is clean! Quality check and packing in progress."
    },
    out_for_delivery: {
      title: 'Out for Delivery',
      push: "We're on our way with your clean laundry! Estimated arrival: {delivery_window}.",
      sms: "Laundry Legends: Your clean laundry is out for delivery! ETA: {delivery_window}"
    },
    delivered: {
      title: 'Delivered!',
      push: "Your laundry has been delivered! Thanks for choosing Laundry Legends. Enjoy your fresh, clean clothes!",
      sms: "Laundry Legends: Your laundry has been delivered! Thanks for choosing us!"
    },
    issue_update: {
      title: 'Issue Update',
      push: "We have an update on your reported issue for Order {order_number}.",
      sms: "Laundry Legends: Update on your issue for Order {order_number}. Check the app for details."
    }
  }.freeze

  def initialize(user:, notification_type:, order: nil, data: {})
    @user = user
    @notification_type = notification_type.to_sym
    @order = order
    @data = data
  end

  def send_all
    template = NOTIFICATION_TEMPLATES[@notification_type]
    return { success: false, error: 'Unknown notification type' } unless template

    results = { push: nil, sms: nil }

    # Send push notification
    if @user.device_tokens.active.any?
      push_result = send_push(template)
      results[:push] = push_result
      log_notification('push', push_result)
    end

    # Send SMS
    if @user.phone.present?
      sms_result = send_sms(template)
      results[:sms] = sms_result
      log_notification('sms', sms_result)
    end

    results
  end

  def send_push_only
    template = NOTIFICATION_TEMPLATES[@notification_type]
    return { success: false, error: 'Unknown notification type' } unless template

    result = send_push(template)
    log_notification('push', result)
    result
  end

  def send_sms_only
    template = NOTIFICATION_TEMPLATES[@notification_type]
    return { success: false, error: 'Unknown notification type' } unless template

    result = send_sms(template)
    log_notification('sms', result)
    result
  end

  private

  def send_push(template)
    title = template[:title]
    body = interpolate_template(template[:push])

    PushNotificationService.new(
      user: @user,
      title: title,
      body: body,
      data: { order_id: @order&.id, notification_type: @notification_type }.compact
    ).send
  end

  def send_sms(template)
    body = interpolate_template(template[:sms])

    SmsNotificationService.new(
      user: @user,
      body: body
    ).send
  end

  def interpolate_template(template)
    result = template.dup

    replacements = {
      '{customer_name}' => @user.first_name,
      '{order_number}' => @order&.formatted_order_number || 'N/A',
      '{bag_count}' => @order&.bag_count&.to_s || 'N/A',
      '{delivery_window}' => @order&.delivery_time_window&.label || 'TBD'
    }

    # Add any custom data replacements
    @data.each do |key, value|
      replacements["{#{key}}"] = value.to_s
    end

    replacements.each do |placeholder, value|
      result.gsub!(placeholder, value)
    end

    result
  end

  def log_notification(channel, result)
    NotificationLog.create!(
      user: @user,
      order: @order,
      channel: channel,
      notification_type: @notification_type.to_s,
      status: result[:success] ? 'sent' : 'failed',
      message: result[:success] ? interpolate_template(NOTIFICATION_TEMPLATES[@notification_type][channel == 'push' ? :push : :sms]) : nil,
      error_message: result[:error],
      metadata: result.except(:success, :error)
    )
  rescue StandardError => e
    Rails.logger.error("Failed to log notification: #{e.message}")
  end
end
