module MapboxConfig
  class << self
    def access_token
      ENV['MAPBOX_ACCESS_TOKEN']
    end

    def configured?
      access_token.present?
    end

    def geocoding_endpoint
      'https://api.mapbox.com/geocoding/v5/mapbox.places'
    end

    def optimization_endpoint
      'https://api.mapbox.com/optimized-trips/v1/mapbox/driving'
    end

    def directions_endpoint
      'https://api.mapbox.com/directions/v5/mapbox/driving'
    end
  end
end
