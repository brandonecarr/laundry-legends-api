class GeocodingService
  def initialize(address)
    @address = address
  end

  def geocode
    return { success: false, error: 'Mapbox not configured' } unless MapboxConfig.configured?
    return { success: false, error: 'No address provided' } unless @address.present?

    begin
      response = connection.get(geocoding_url)

      if response.success?
        data = JSON.parse(response.body)
        features = data['features']

        if features.present? && features.first.present?
          coordinates = features.first['center']
          {
            success: true,
            longitude: coordinates[0],
            latitude: coordinates[1],
            formatted_address: features.first['place_name']
          }
        else
          { success: false, error: 'No results found' }
        end
      else
        { success: false, error: "Mapbox API error: #{response.status}" }
      end
    rescue Faraday::Error => e
      Rails.logger.error("Geocoding Error: #{e.message}")
      { success: false, error: e.message }
    rescue JSON::ParserError => e
      Rails.logger.error("Geocoding JSON Error: #{e.message}")
      { success: false, error: 'Invalid response from geocoding service' }
    end
  end

  def self.geocode_string(address_string)
    new(nil).geocode_address_string(address_string)
  end

  def geocode_address_string(address_string)
    return { success: false, error: 'Mapbox not configured' } unless MapboxConfig.configured?
    return { success: false, error: 'No address provided' } unless address_string.present?

    begin
      encoded_address = URI.encode_www_form_component(address_string)
      url = "#{MapboxConfig.geocoding_endpoint}/#{encoded_address}.json?access_token=#{MapboxConfig.access_token}&country=US&limit=1"

      response = connection.get(url)

      if response.success?
        data = JSON.parse(response.body)
        features = data['features']

        if features.present? && features.first.present?
          coordinates = features.first['center']
          {
            success: true,
            longitude: coordinates[0],
            latitude: coordinates[1],
            formatted_address: features.first['place_name']
          }
        else
          { success: false, error: 'No results found' }
        end
      else
        { success: false, error: "Mapbox API error: #{response.status}" }
      end
    rescue Faraday::Error => e
      Rails.logger.error("Geocoding Error: #{e.message}")
      { success: false, error: e.message }
    rescue JSON::ParserError => e
      Rails.logger.error("Geocoding JSON Error: #{e.message}")
      { success: false, error: 'Invalid response from geocoding service' }
    end
  end

  private

  def connection
    @connection ||= Faraday.new do |conn|
      conn.options.timeout = 10
      conn.options.open_timeout = 5
      conn.adapter Faraday.default_adapter
    end
  end

  def geocoding_url
    address_string = build_address_string
    encoded_address = URI.encode_www_form_component(address_string)
    "#{MapboxConfig.geocoding_endpoint}/#{encoded_address}.json?access_token=#{MapboxConfig.access_token}&country=US&limit=1"
  end

  def build_address_string
    parts = []
    parts << @address.street_address if @address.respond_to?(:street_address)
    parts << @address.city if @address.respond_to?(:city)
    parts << @address.state if @address.respond_to?(:state)
    parts << @address.zip_code if @address.respond_to?(:zip_code)
    parts.compact.join(', ')
  end
end
