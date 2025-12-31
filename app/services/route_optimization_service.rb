class RouteOptimizationService
  MAX_WAYPOINTS = 12

  def initialize(orders:, start_location: nil, end_location: nil, optimize_for: :time)
    @orders = orders
    @start_location = start_location || default_start_location
    @end_location = end_location || @start_location
    @optimize_for = optimize_for
  end

  def optimize
    return { success: false, error: 'Mapbox not configured' } unless MapboxConfig.configured?
    return { success: false, error: 'No orders to optimize' } if @orders.empty?

    if @orders.size > MAX_WAYPOINTS
      return { success: false, error: "Too many waypoints (max #{MAX_WAYPOINTS})" }
    end

    geocoded_orders = geocode_orders
    missing_geocodes = geocoded_orders.select { |o| o[:latitude].nil? || o[:longitude].nil? }

    if missing_geocodes.any?
      return {
        success: false,
        error: 'Some addresses could not be geocoded',
        missing_addresses: missing_geocodes.map { |o| o[:order].id }
      }
    end

    optimize_route(geocoded_orders)
  end

  def estimate_route
    return { success: false, error: 'Mapbox not configured' } unless MapboxConfig.configured?
    return { success: false, error: 'No orders to estimate' } if @orders.empty?

    geocoded_orders = geocode_orders
    valid_orders = geocoded_orders.reject { |o| o[:latitude].nil? || o[:longitude].nil? }

    return { success: false, error: 'No valid geocoded addresses' } if valid_orders.empty?

    calculate_simple_route(valid_orders)
  end

  private

  def default_start_location
    {
      latitude: ENV.fetch('FACILITY_LATITUDE', '33.7490').to_f,
      longitude: ENV.fetch('FACILITY_LONGITUDE', '-84.3880').to_f,
      name: 'Laundry Legends Facility'
    }
  end

  def geocode_orders
    @orders.map do |order|
      address = order.address
      lat = address&.latitude
      lng = address&.longitude

      if lat.nil? || lng.nil?
        result = GeocodingService.new(address).geocode
        if result[:success]
          lat = result[:latitude]
          lng = result[:longitude]
          address.update(latitude: lat, longitude: lng) if address
        end
      end

      {
        order: order,
        latitude: lat,
        longitude: lng,
        address_string: address ? "#{address.street_address}, #{address.city}" : 'Unknown'
      }
    end
  end

  def optimize_route(geocoded_orders)
    coordinates = build_coordinates_string(geocoded_orders)
    url = "#{MapboxConfig.optimization_endpoint}/#{coordinates}?access_token=#{MapboxConfig.access_token}&source=first&destination=last&roundtrip=false&geometries=geojson"

    begin
      response = connection.get(url)

      if response.success?
        data = JSON.parse(response.body)

        if data['code'] == 'Ok' && data['trips'].present?
          trip = data['trips'].first
          waypoints = data['waypoints']

          optimized_order = waypoints.sort_by { |w| w['waypoint_index'] }
          order_sequence = optimized_order.map { |w| geocoded_orders[w['trips_index']][:order] }.compact

          {
            success: true,
            optimized_orders: order_sequence,
            total_duration_seconds: trip['duration'],
            total_distance_meters: trip['distance'],
            total_duration_minutes: (trip['duration'] / 60.0).round(1),
            total_distance_miles: (trip['distance'] / 1609.34).round(2),
            geometry: trip['geometry'],
            waypoints: waypoints.map.with_index do |w, idx|
              next if idx == 0 || idx == waypoints.length - 1
              order_info = geocoded_orders[w['trips_index'] - 1]
              next unless order_info

              {
                order_id: order_info[:order]&.id,
                order_number: order_info[:order]&.formatted_order_number,
                address: order_info[:address_string],
                waypoint_index: w['waypoint_index'],
                latitude: w['location'][1],
                longitude: w['location'][0]
              }
            end.compact
          }
        else
          { success: false, error: data['message'] || 'Optimization failed' }
        end
      else
        { success: false, error: "Mapbox API error: #{response.status}" }
      end
    rescue Faraday::Error => e
      Rails.logger.error("Route Optimization Error: #{e.message}")
      { success: false, error: e.message }
    rescue JSON::ParserError => e
      Rails.logger.error("Route Optimization JSON Error: #{e.message}")
      { success: false, error: 'Invalid response from optimization service' }
    end
  end

  def calculate_simple_route(geocoded_orders)
    coordinates = build_coordinates_string(geocoded_orders)
    url = "#{MapboxConfig.directions_endpoint}/#{coordinates}?access_token=#{MapboxConfig.access_token}&geometries=geojson&overview=full"

    begin
      response = connection.get(url)

      if response.success?
        data = JSON.parse(response.body)

        if data['code'] == 'Ok' && data['routes'].present?
          route = data['routes'].first

          {
            success: true,
            total_duration_seconds: route['duration'],
            total_distance_meters: route['distance'],
            total_duration_minutes: (route['duration'] / 60.0).round(1),
            total_distance_miles: (route['distance'] / 1609.34).round(2),
            geometry: route['geometry'],
            legs: route['legs'].map.with_index do |leg, idx|
              {
                duration_seconds: leg['duration'],
                distance_meters: leg['distance'],
                summary: leg['summary']
              }
            end
          }
        else
          { success: false, error: data['message'] || 'Directions request failed' }
        end
      else
        { success: false, error: "Mapbox API error: #{response.status}" }
      end
    rescue Faraday::Error => e
      Rails.logger.error("Route Calculation Error: #{e.message}")
      { success: false, error: e.message }
    rescue JSON::ParserError => e
      Rails.logger.error("Route Calculation JSON Error: #{e.message}")
      { success: false, error: 'Invalid response from directions service' }
    end
  end

  def build_coordinates_string(geocoded_orders)
    coords = []
    coords << "#{@start_location[:longitude]},#{@start_location[:latitude]}"

    geocoded_orders.each do |go|
      coords << "#{go[:longitude]},#{go[:latitude]}"
    end

    coords << "#{@end_location[:longitude]},#{@end_location[:latitude]}" if @end_location != @start_location

    coords.join(';')
  end

  def connection
    @connection ||= Faraday.new do |conn|
      conn.options.timeout = 30
      conn.options.open_timeout = 10
      conn.adapter Faraday.default_adapter
    end
  end
end
