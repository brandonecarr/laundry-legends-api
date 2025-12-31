class GeocodeAddressJob < ApplicationJob
  queue_as :geocoding

  def perform(address_id)
    address = Address.find_by(id: address_id)
    return unless address

    result = GeocodingService.new(address).geocode

    if result[:success]
      address.update(
        latitude: result[:latitude],
        longitude: result[:longitude]
      )
      Rails.logger.info("Geocoded address #{address_id}: #{result[:latitude]}, #{result[:longitude]}")
    else
      Rails.logger.error("Failed to geocode address #{address_id}: #{result[:error]}")
    end
  end
end
