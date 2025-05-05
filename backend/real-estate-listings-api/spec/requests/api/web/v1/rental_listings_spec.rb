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
  end
end
