class SmsNotificationService
  def initialize(user:, body:)
    @user = user
    @body = body
  end

  def send
    return { success: false, error: 'Twilio not configured' } unless TwilioConfig.configured?
    return { success: false, error: 'User has no phone number' } unless @user.phone.present?

    begin
      message = TwilioConfig.client.messages.create(
        from: TwilioConfig.phone_number,
        to: formatted_phone_number,
        body: @body
      )

      {
        success: true,
        sid: message.sid,
        status: message.status
      }
    rescue Twilio::REST::RestError => e
      Rails.logger.error("Twilio Error: #{e.message}")
      { success: false, error: e.message }
    rescue StandardError => e
      Rails.logger.error("SMS Error: #{e.message}")
      { success: false, error: e.message }
    end
  end

  private

  def formatted_phone_number
    phone = @user.phone.gsub(/\D/, '')
    phone = "+1#{phone}" unless phone.start_with?('1')
    phone = "+#{phone}" unless phone.start_with?('+')
    phone
  end
end
