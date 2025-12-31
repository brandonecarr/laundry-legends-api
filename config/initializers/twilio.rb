# Twilio SMS Configuration

module TwilioConfig
  class << self
    def configured?
      account_sid.present? && auth_token.present? && phone_number.present?
    end

    def account_sid
      ENV['TWILIO_ACCOUNT_SID']
    end

    def auth_token
      ENV['TWILIO_AUTH_TOKEN']
    end

    def phone_number
      ENV['TWILIO_PHONE_NUMBER']
    end

    def client
      return nil unless configured?
      @client ||= Twilio::REST::Client.new(account_sid, auth_token)
    end
  end
end
