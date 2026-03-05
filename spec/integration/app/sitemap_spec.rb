require "spec_helper"
require "spec/support/diskspace_test_helpers"
require "spec/support/connectivity_test_helpers"

RSpec.describe "SitemapTest" do
  let(:bucket) { "test-bucket" }
  let(:body_content) do
    <<~XML
      <urlset>
        <url><loc>https://example.com/</loc></url>
        <url><loc>https://example.com/about</loc></url>
      </urlset>
    XML
  end
  describe "get /sitemap.xml" do
    it "streams the sitemap XML from S3" do
      ClimateControl.modify AWS_S3_SITEMAPS_BUCKET_NAME: bucket do
        allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
        Services.s3_client.put_object(key: "sitemap.xml",
                                      bucket:,
                                      body: body_content)
        get "/sitemap.xml"

        expect(last_response.status).to eq(200)
        expect(last_response.headers["Content-Type"]).to eq("application/xml")
        expect(last_response.headers["Cache-Control"]).to eq("public")
        expect(last_response.headers["Last-Modified"]).to eq(FakeS3::LAST_MODIFIED.httpdate)
        expect(last_response.body).to eq(body_content)
      end
    end
  end
  describe "get /sitemaps/:sitemap" do
    it "streams the sitemap XML from S3" do
      ClimateControl.modify AWS_S3_SITEMAPS_BUCKET_NAME: bucket do
        allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
        Services.s3_client.put_object(key: "something.xml",
                                      bucket:,
                                      body: body_content)
        get "/sitemaps/something.xml"

        expect(last_response.status).to eq(200)
        expect(last_response.headers["Content-Type"]).to eq("application/xml")
        expect(last_response.headers["Cache-Control"]).to eq("public")
        expect(last_response.headers["Last-Modified"]).to eq(FakeS3::LAST_MODIFIED.httpdate)
        expect(last_response.body).to eq(body_content)
      end
    end
    it "cannot find the sitemap" do
      ClimateControl.modify AWS_S3_SITEMAPS_BUCKET_NAME: bucket do
        allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
        get "/sitemaps/something.xml"

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq("No such object")
      end
    end
  end

  describe "post /sitemaps/*" do
    it "returns a 405 error message" do
      post "/sitemaps/server/anything/stuff.php"
      expect(last_response.status).to eq(405)
      expect(last_response.headers["Allow"]).to eq("GET")
      expect(last_response.body).to eq({ message: "Method Not Allowed: Use GET to access the sitemap." }.to_json)
    end
  end
end
