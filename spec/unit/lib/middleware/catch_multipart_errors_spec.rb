require "spec_helper"
require "lib/middleware/catch_multipart_errors"

RSpec.describe Middleware::CatchMultipartErrors do
  include Rack::Test::Methods

  let(:sinatra_app) do
    ->(_env) { [200, { "Content-Type" => "text/plain" }, ["All good!"]] }
  end

  let(:app) { Middleware::CatchMultipartErrors.new(sinatra_app) }

  let(:empty_form_data) { "\n" }

  it "catches multipart errors" do
    header "Content-Type", "multipart/form-data; boundary=----TestBoundary"

    post "/sitemaps/anything.php", empty_form_data

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("Bad request")
  end
end
