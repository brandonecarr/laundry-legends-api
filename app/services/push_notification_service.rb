class PushNotificationService
  def initialize(user:, title:, body:, data: {})
    @user = user
    @title = title
    @body = body
    @data = data
  end

  def send
    return { success: false, error: 'APNs not configured' } unless ApnsConfig.configured?

    device_tokens = @user.device_tokens.active.ios

    if device_tokens.empty?
      return { success: false, error: 'No active device tokens' }
    end

    results = device_tokens.map do |device_token|
      send_to_device(device_token)
    end

    successful = results.count { |r| r[:success] }
    failed = results.count { |r| !r[:success] }

    {
      success: successful > 0,
      sent: successful,
      failed: failed,
      results: results
    }
  end

  private

  def send_to_device(device_token)
    connection = Apnotic::Connection.new(
      auth_method: :token,
      cert_path: ApnsConfig.key_path,
      key_id: ApnsConfig.key_id,
      team_id: ApnsConfig.team_id
    )

    notification = Apnotic::Notification.new(device_token.token)
    notification.topic = ApnsConfig.bundle_id
    notification.alert = {
      title: @title,
      body: @body
    }
    notification.custom_payload = @data if @data.present?
    notification.sound = 'default'

    response = connection.push(notification)
    connection.close

    if response.ok?
      { success: true, token: device_token.token }
    else
      # Mark token as inactive if it's invalid
      if response.status == '410' || response.status == '400'
        device_token.update(active: false)
      end

      { success: false, token: device_token.token, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("APNs Error: #{e.message}")
    { success: false, token: device_token.token, error: e.message }
  end
end
