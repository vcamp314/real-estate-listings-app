class Api::Web::V1::RentalListingsController < ApplicationController
  require 'csv'

  BUILDING_TYPE_MAPPING = {
    'アパート' => :apartment,
    'マンション' => :condominium,
    '一戸建て' => :detached
  }.freeze

  # POST /api/web/v1/rental_listings
  def create
    if params[:file].blank?
      return render json: { error: 'No file provided' }, status: :unprocessable_entity
    end

    unless params[:file].content_type == 'text/csv'
      return render json: { error: 'File must be a CSV' }, status: :unprocessable_entity
    end

    begin
      csv_content = params[:file].read.force_encoding('UTF-8')
      csv_data = CSV.parse(csv_content, headers: true, encoding: 'UTF-8')

      
      records = csv_data.map do |row|
        building_type = BUILDING_TYPE_MAPPING[row['建物の種類']&.strip]
        unless building_type
          raise ArgumentError, "Invalid building type: #{row['建物の種類']}"
        end

        record = {
          id: row['ユニークID'].to_i,
          name: row['物件名'],
          address: row['住所'],
          apartment_number: row['部屋番号'],
          rent: row['賃料'].to_i,
          floor_area: row['広さ'].to_f,
          building_type: building_type,
          created_at: Time.current,
          updated_at: Time.current
        }

        # Validate the record
        rental_listing = RentalListing.new(record)
        unless rental_listing.valid?
          raise ArgumentError, "Invalid record: #{rental_listing.errors.full_messages.join(', ')}"
        end

        record
      end
      
      RentalListing.upsert_all(
        records,
        update_only: [:name, :address, :apartment_number, :rent, :floor_area, :building_type, :updated_at]
      )

      render json: { message: 'Bulk upsert completed successfully' }, status: :created
    rescue CSV::MalformedCSVError => e
      render json: { error: 'Invalid CSV format' }, status: :unprocessable_entity
    rescue ArgumentError => e
      render json: { error: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
