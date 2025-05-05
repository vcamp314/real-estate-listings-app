class CreateRentalListings < ActiveRecord::Migration[8.0]
  def change
    create_table :rental_listings, id: false do |t|
      t.integer :id, primary_key: true
      t.string :name, null: false
      t.string :address, null: true
      t.string :apartment_number, null: true
      t.integer :rent, null: true
      t.decimal :floor_area, null: true
      t.integer :building_type, null: true

      t.timestamps
    end
  end
end
