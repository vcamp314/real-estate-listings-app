class RentalListing < ApplicationRecord
    validates :id, :name, presence: true
    validates :floor_area, numericality: { greater_than: 0 }
    validates :rent, numericality: { greater_than: 0 }

    enum :building_type, {
        apartment: 1,
        detached: 2,
        condominium: 3
    }

    validates :building_type, inclusion: { in: building_types.keys }
end