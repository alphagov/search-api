require 'spec_helper'

RSpec.describe 'AuthorizationTests' do
  around do |example|
    ClimateControl.modify(GDS_SSO_STRATEGY: "real") { example.run }
  end

  it "receives a 401 response with invalid request error when no bearer token is provided" do
    response = post "/government_test/commit", {}.to_json

    expect(response.status).to eq(401)
    expect(response.original_headers.fetch('WWW-Authenticate')).to eq('Bearer error=invalid_request')
  end

  it "receives a 401 response wth invalid token error when bearer token is not valid" do
    allow_any_instance_of(Auth::GdsSso).to receive(:locate).and_return(nil)

    header "Authorization", "Bearer 1234"

    response = post "/government_test/commit", {}.to_json

    expect(response.status).to eq(401)
    expect(response.original_headers.fetch('WWW-Authenticate')).to eq('Bearer error=invalid_token')
  end

  it "receives a 200 response when bearer token is provided and is valid" do
    stub_request(:get, "http://signon.dev.gov.uk/user.json?client_id=")
      .with(
        headers: {
          "Authorization"=>"Bearer VALID-BEARER-TOKEN"
        })
      .to_return(status: 200, body: '{ "user": { "uid": 123 } }')

    header "Authorization", "Bearer VALID-BEARER-TOKEN"

    response = post "/government_test/commit", {}.to_json

    expect(response.status).to eq(200)
  end
end
