class Api::Web::V1::RentalListingsController < ApplicationController
  require 'csv'

  BUILDING_TYPE_MAPPING = {
    'アパート' => :apartment,
    'マンション' => :condominium,
    '一戸建て' => :detached
  }.freeze

  BATCH_SIZE = 1000 # Process 1000 records at a time

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
      total_rows = csv_data.count

      valid_records = []
      errors_hash = {}
      
      # Process in batches
      csv_data.each_slice(BATCH_SIZE).with_index do |batch, batch_index|
        batch.each_with_index do |row, index|
          row_number = (batch_index * BATCH_SIZE) + index + 2 # Adding 2 because index is 0-based and we want to account for header row
          
          process_csv_row(row, row_number, valid_records, errors_hash)
        end

        # Process valid records in the current batch
        if valid_records.any?
          RentalListing.upsert_all(valid_records)
          valid_records.clear # Clear the array after processing
        end

        # Log progress
        Rails.logger.info("Processed batch #{batch_index + 1}, #{((batch_index + 1) * BATCH_SIZE)}/#{total_rows} rows")
      end

      # Calculate unique rows with errors
      rows_with_errors = errors_hash.keys.map { |key| key.split(':').first }.uniq.size

      response = {
        message: 'Processing completed',
        total_rows: total_rows,
        processed_count: total_rows - rows_with_errors,
        error_count: errors_hash.size
      }

      if errors_hash.any?
        response[:errors] = errors_hash.values
      end

      # Return partial_content if there are any errors, even if some records were processed
      status = if errors_hash.any?
                :partial_content
              elsif response[:processed_count] > 0
                :created
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

  private

  def process_csv_row(row, row_number, valid_records, errors_hash)
    begin
      building_type = BUILDING_TYPE_MAPPING[row['建物の種類']&.strip]

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
        valid_records << record
      else
        rental_listing.errors.each do |error|
          errors_hash["#{row_number}:#{error.attribute}"] = { row: row_number, column: error.attribute.to_s }
        end
      end
    rescue ArgumentError => e
      errors_hash["#{row_number}:format"] = { row: row_number, column: 'format' }
    end
  end
end
