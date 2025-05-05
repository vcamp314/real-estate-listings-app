class RentalListing < ApplicationRecord
    validates :id, :address, :rent, :floor_area, :building_type, presence: true
    validates :floor_area, numericality: { greater_than: 0 }
    validates :id, uniqueness: true

    enum :building_type, {
        apartment: 1,
        detached: 2,
        condominium: 3
    }

    validates :building_type, inclusion: { in: building_types.keys }
end