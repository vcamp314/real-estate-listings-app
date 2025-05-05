require 'rails_helper'

RSpec.describe "/api/web/v1/rental_listings", type: :request do

  # This should return the minimal set of values that should be in the headers
  # in order to pass any filters (e.g. authentication) defined in
  # Api::Web::V1::RentalListingsController, or in your router and rack
  # middleware. Be sure to keep this updated too.
  let(:valid_headers) {
    {}
  }

  describe "POST /create" do
    context "with valid CSV file" do
      it "creates new RentalListings from CSV" do
        file = fixture_file_upload('valid_rental_listings.csv', 'text/csv')

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: file },
               headers: valid_headers
        }.to change(RentalListing, :count).by(3)
      end

      it "renders a success message" do
        file = fixture_file_upload('valid_rental_listings.csv', 'text/csv')

        post api_web_v1_rental_listings_url,
             params: { file: file },
             headers: valid_headers

        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
        expect(JSON.parse(response.body)).to include(
          "message" => "Processing completed",
          "processed_count" => 3,
          "error_count" => 0
        )
      end

      it "updates existing records based on id" do
        # First create a record
        file = fixture_file_upload('valid_rental_listings.csv', 'text/csv')
        post api_web_v1_rental_listings_url,
             params: { file: file },
             headers: valid_headers

        # Then update the same record with modified data
        updated_file = fixture_file_upload('updated_rental_listing.csv', 'text/csv')

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: updated_file },
               headers: valid_headers
        }.to change(RentalListing, :count).by(0)

        updated_listing = RentalListing.find_by(id: 1)
        expect(updated_listing.name).to eq("シーサイドアパート改")
        expect(updated_listing.rent).to eq(200000)
      end
    end

    context "with invalid CSV file" do
      it "returns error when no file is provided" do
        post api_web_v1_rental_listings_url,
             params: {},
             headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("error" => "No file provided")
      end

      it "returns error when file is not a CSV" do
        file = fixture_file_upload('valid_rental_listings.csv', 'text/plain')

        post api_web_v1_rental_listings_url,
             params: { file: file },
             headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("error" => "File must be a CSV")
      end

      it "returns error for malformed CSV" do
        file = fixture_file_upload('malformed.csv', 'text/csv')

        post api_web_v1_rental_listings_url,
             params: { file: file },
             headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to include("error" => "Invalid CSV format")
      end
    end

    context "with partially valid CSV file" do
      it "processes valid rows and returns errors for invalid ones" do
        file = fixture_file_upload('mixed_validity_rental_listings.csv', 'text/csv')

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: file },
               headers: valid_headers
        }.to change(RentalListing, :count).by(2) # Only valid rows should be processed

        expect(response).to have_http_status(:partial_content)
        response_body = JSON.parse(response.body)
        
        expect(response_body).to include(
          "message" => "Processing completed",
          "processed_count" => 2,
          "error_count" => 1
        )
        
        expect(response_body["errors"]).to contain_exactly(
          {
            "row" => 4,
            "column" => "building_type"
          }
        )
      end

      it "handles multiple validation errors in the same row" do
        file = fixture_file_upload('multiple_errors_rental_listings.csv', 'text/csv')

        post api_web_v1_rental_listings_url,
             params: { file: file },
             headers: valid_headers

        expect(response).to have_http_status(:partial_content)
        response_body = JSON.parse(response.body)
        
        expect(response_body["error_count"]).to be > 1
        expect(response_body["errors"].length).to be > 1
        
        # Verify that errors contain both row and column information
        response_body["errors"].each do |error|
          expect(error).to include("row", "column")
        end
      end

      it "processes valid rows even when some rows have format errors" do
        file = fixture_file_upload('format_errors_rental_listings.csv', 'text/csv')

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: file },
               headers: valid_headers
        }.to change(RentalListing, :count).by(2)

        expect(response).to have_http_status(:partial_content)
        response_body = JSON.parse(response.body)
        
        expect(response_body["processed_count"]).to eq(2)
        expect(response_body["errors"]).to include(
          {
            "row" => 2,
            "column" => "rent"
          }
        )
      end
    end

    context "with apartment number validation" do
      it "requires apartment number for apartment building type" do
        file = fixture_file_upload('apartment_without_number.csv', 'text/csv')

        post api_web_v1_rental_listings_url,
             params: { file: file },
             headers: valid_headers

        expect(response).to have_http_status(:partial_content)
        response_body = JSON.parse(response.body)
        
        expect(response_body["errors"]).to include(
          {
            "row" => 3,
            "column" => "apartment_number"
          }
        )
      end

      it "allows missing apartment number for non-apartment building types" do
        file = fixture_file_upload('non_apartment_without_number.csv', 'text/csv')

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: file },
               headers: valid_headers
        }.to change(RentalListing, :count).by(2)

        expect(response).to have_http_status(:created)
        response_body = JSON.parse(response.body)
        expect(response_body["error_count"]).to eq(0)
      end

      it "processes valid apartments with apartment numbers" do
        file = fixture_file_upload('valid_apartments.csv', 'text/csv')

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: file },
               headers: valid_headers
        }.to change(RentalListing, :count).by(2)

        expect(response).to have_http_status(:created)
        response_body = JSON.parse(response.body)
        expect(response_body["error_count"]).to eq(0)
      end
    end

    context "with name validation" do
      it "requires name for all rental listings" do
        file = fixture_file_upload('missing_name_rental_listings.csv', 'text/csv')

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: file },
               headers: valid_headers
        }.to change(RentalListing, :count).by(2)

        expect(response).to have_http_status(:partial_content)
        response_body = JSON.parse(response.body)
        
        expect(response_body["processed_count"]).to eq(2)
        expect(response_body["error_count"]).to eq(1)
        expect(response_body["errors"]).to include(
          {
            "row" => 3,
            "column" => "name"
          }
        )
      end
    end

    context "when CSV contains invalid IDs" do
      let(:file) { fixture_file_upload("invalid_id_rental_listings.csv", "text/csv") }

      it "returns errors for invalid IDs" do
        post "/api/web/v1/rental_listings", params: { file: file }
        expect(response).to have_http_status(:partial_content)
        json_response = JSON.parse(response.body)
        
        expect(json_response["errors"]).to include(
          {
            "row" => 3,
            "column" => "id",
          },
          {
            "row" => 4,
            "column" => "id",
          },
          {
            "row" => 5,
            "column" => "id",
          }
        )

        # Verify that valid rows are still processed
        expect(RentalListing.find_by(id: 1)).to be_present
      end
    end

    context "with batch processing" do
      it "processes all rows in a large CSV file" do
        # Create a CSV with more rows than BATCH_SIZE
        large_csv = generate_large_csv(1500) # More than BATCH_SIZE (1000)
        file = Tempfile.new(['large_rental_listings', '.csv'])
        file.write(large_csv)
        file.rewind

        expect {
          post api_web_v1_rental_listings_url,
               params: { file: Rack::Test::UploadedFile.new(file.path, 'text/csv') },
               headers: valid_headers
        }.to change(RentalListing, :count).by(1500)

        expect(response).to have_http_status(:created)
        response_body = JSON.parse(response.body)
        expect(response_body["total_rows"]).to eq(1500)
        expect(response_body["processed_count"]).to eq(1500)
        expect(response_body["error_count"]).to eq(0)

        # Verify all IDs are present
        (1..1500).each do |id|
          expect(RentalListing.find_by(id: id)).to be_present
        end
      end

      it "handles errors correctly across batch boundaries" do
        # Create a CSV with errors at batch boundaries
        error_boundary_csv = generate_error_boundary_csv
        file = Tempfile.new(['error_boundary_rental_listings', '.csv'])
        file.write(error_boundary_csv)
        file.rewind

        post api_web_v1_rental_listings_url,
             params: { file: Rack::Test::UploadedFile.new(file.path, 'text/csv') },
             headers: valid_headers

        expect(response).to have_http_status(:partial_content)
        response_body = JSON.parse(response.body)
        
        # Verify error rows were caught
        expect(response_body["errors"]).to include(
          { "row" => 999, "column" => "name" },
          { "row" => 1000, "column" => "name" },
          { "row" => 1001, "column" => "name" }
        )
        
        # Verify valid rows were processed
        expect(response_body["processed_count"]).to eq(998) # 1000 - 3 error rows
      end
    end
  end

  private

  def generate_large_csv(row_count)
    headers = "ユニークID,物件名,住所,部屋番号,賃料,広さ,建物の種類\n"
    rows = (1..row_count).map do |id| # starts from 1 to ensure row_count number of rows are created
      "#{id},テスト物件#{id},テスト住所#{id},#{id}号室,#{id * 10000},#{id * 10},マンション"
    end
    headers + rows.join("\n")
  end

  def generate_error_boundary_csv
    headers = "ユニークID,物件名,住所,部屋番号,賃料,広さ,建物の種類\n"
    rows = (2..1002).map do |id| # starts from 2 because of the header row (which is 1) in order to match the row positions in the below if statement
      if [999, 1000, 1001].include?(id)
        "#{id},,テスト住所#{id},#{id}号室,#{id * 10000},#{id * 10},マンション" # Missing name
      else
        "#{id},テスト物件#{id},テスト住所#{id},#{id}号室,#{id * 10000},#{id * 10},マンション"
      end
    end
    headers + rows.join("\n")
  end
end
