class CreateRentalListings < ActiveRecord::Migration[8.0]
  def change
    create_table :rental_listings, id: false do |t|
      t.integer :id, primary_key: true
      t.string :name, null: true
      t.string :address, null: false
      t.string :apartment_number, null: true
      t.integer :rent, null: false
      t.decimal :floor_area, null: false
      t.integer :building_type, null: false

      t.timestamps
    end
  end
end
