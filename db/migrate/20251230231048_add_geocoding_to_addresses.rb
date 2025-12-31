class AddGeocodingToAddresses < ActiveRecord::Migration[7.1]
  def change
    add_column :addresses, :latitude, :decimal, precision: 10, scale: 6
    add_column :addresses, :longitude, :decimal, precision: 10, scale: 6
    add_index :addresses, [:latitude, :longitude]
  end
end
