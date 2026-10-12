require "spec_helper"
require "lib/middleware/sitemap_bot_blocker"

RSpec.describe Middleware::SitemapBotBlocker do
  include Rack::Test::Methods

  let(:sinatra_app) do
    ->(_env) { [200, { "Content-Type" => "text/plain" }, ["All good!"]] }
  end

  let(:app) { Middleware::SitemapBotBlocker.new(sinatra_app) }

  let(:empty_form_data) { "\n" }

  it "lets valid sitemap GET requests pass through" do
    get "/sitemap.xml"
    expect(last_response.status).to eq 200
  end

  it "blocks all post requests" do
    header "Content-Type", "multipart/form-data; boundary=----TestBoundary"

    post "/sitemaps/anything.php", empty_form_data

    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("Bad request")
  end
end
