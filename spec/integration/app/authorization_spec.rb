require "spec_helper"

RSpec.describe "AuthorizationTests" do
  context "when signin is invalid" do
    let(:gds_sso_instance) { instance_double(Auth::GdsSso) }

    around do |example|
      ClimateControl.modify(GDS_SSO_MOCK_INVALID: "true") { example.run }
    end

    it "receives a response with invalid request error when no bearer token is provided" do
      response = post "/unauthenticated", {}.to_json

      expect(response.original_headers.fetch("WWW-Authenticate")).to eq("Bearer error=invalid_request")
    end

    it "receives a response wth invalid token error when bearer token is not valid" do
      header "Authorization", "Bearer 1234"

      response = post "/unauthenticated", {}.to_json

      expect(response.original_headers.fetch("WWW-Authenticate")).to eq("Bearer error=invalid_token")
    end

    it "prevents access to a route that requires authentication when no authentication is provided" do
      response = post "/government_test/commit", {}.to_json

      expect(response.status).to eq(401)
    end
  end
end
