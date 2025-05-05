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

      valid_records = []
      errors_hash = {} # using a hash to store errors to avoid duplicates
      
      csv_data.each_with_index do |row, index|
        row_number = index + 2 # Adding 2 because index is 0-based and we want to account for header row
        
        begin
          building_type = BUILDING_TYPE_MAPPING[row['建物の種類']&.strip]
          # apartments must have an apartment number
          if building_type && building_type == :apartment && row['部屋番号'].blank?
            error_key = "#{row_number}:apartment_number"
            errors_hash[error_key] = { row: row_number, column: 'apartment_number' }
          end

          Rails.logger.info("row_errors: #{errors_hash}")

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
          if rental_listing.valid?
            Rails.logger.info("valid_record")
            valid_records << record
          else
            Rails.logger.info("invalid_record")
            rental_listing.errors.each do |error|
              error_key = "#{row_number}:#{error.attribute}"
              errors_hash[error_key] = { row: row_number, column: error.attribute.to_s }
            end
          end
        rescue ArgumentError => e
          error_key = "#{row_number}:format"
          errors_hash[error_key] = { row: row_number, column: 'format' }
        end
      end
      
      if valid_records.any?
        RentalListing.upsert_all(valid_records)
      end

      response = {
        message: 'Processing completed',
        processed_count: valid_records.size,
        error_count: errors_hash.size
      }

      if errors_hash.any?
        response[:errors] = errors_hash.values
      end

      # Only return partial_content if we actually processed some records
      status = if valid_records.any?
                errors_hash.any? ? :partial_content : :created
              else
                :unprocessable_entity
              end

      render json: response, status: status
    rescue CSV::MalformedCSVError => e
      render json: { error: 'Invalid CSV format' }, status: :unprocessable_entity
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
