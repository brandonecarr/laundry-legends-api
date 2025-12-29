# app/models/address.rb

class Address < ApplicationRecord
  belongs_to :user

  validates :label, presence: true
  validates :street_address, presence: true
  validates :city, presence: true
  validates :state, presence: true
  validates :zip_code, presence: true

  def formatted_address
    parts = [street_address]
    parts << unit if unit.present?
    parts << "#{city}, #{state} #{zip_code}"
    parts.join("\n")
  end

  def short_address
    "#{street_address}, #{city}"
  end
end
