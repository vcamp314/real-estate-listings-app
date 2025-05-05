require "rails_helper"

RSpec.describe Api::Web::V1::RentalListingsController, type: :routing do
  describe "routing" do

    it "routes to #create" do
      expect(post: "/api/web/v1/rental_listings").to route_to("api/web/v1/rental_listings#create")
    end
  end
end
