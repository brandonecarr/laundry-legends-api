# Apple Push Notification Service (APNs) Configuration
# Uses the apnotic gem for HTTP/2 APNs connections

module ApnsConfig
  class << self
    def configured?
      ENV['APNS_KEY_ID'].present? &&
        ENV['APNS_TEAM_ID'].present? &&
        ENV['APNS_BUNDLE_ID'].present? &&
        apns_key_exists?
    end

    def key_id
      ENV['APNS_KEY_ID']
    end

    def team_id
      ENV['APNS_TEAM_ID']
    end

    def bundle_id
      ENV['APNS_BUNDLE_ID']
    end

    def key_path
      ENV.fetch('APNS_KEY_PATH', Rails.root.join('config', 'apns_key.p8').to_s)
    end

    def environment
      Rails.env.production? ? :production : :development
    end

    private

    def apns_key_exists?
      File.exist?(key_path)
    end
  end
end
