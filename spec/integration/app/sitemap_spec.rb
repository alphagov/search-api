require "spec_helper"

RSpec.shared_examples "will respond with a 404 if formats other than xml are requested" do |path|
  it "get requests are halted" do
    get path
    expect(last_response.status).to eq(404)
  end
end

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
  describe "get /sitemap" do
    it_behaves_like "will respond with a 404 if formats other than xml are requested", "/sitemap.php"

    it "streams the sitemap XML from S3" do
      ClimateControl.modify AWS_S3_SITEMAPS_BUCKET_NAME: bucket do
        allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
        Services.s3_client.put_object(key: "sitemap.xml",
                                      bucket:,
                                      body: body_content)
        ["/sitemap.xml", "/sitemap"].each do |path|
          get path
          expect(last_response.status).to eq(200)
          expect(last_response.headers["Content-Type"]).to eq("application/xml")
          expect(last_response.headers["Cache-Control"]).to eq("public")
          expect(last_response.headers["Last-Modified"]).to eq(FakeS3::LAST_MODIFIED.httpdate)
          expect(last_response.body).to eq(body_content)
        end
      end
    end
  end

  describe "get /sitemaps/:sitemap" do
    it_behaves_like "will respond with a 404 if formats other than xml are requested", "/sitemaps/something.php"

    it "streams the sitemap XML from S3" do
      ClimateControl.modify AWS_S3_SITEMAPS_BUCKET_NAME: bucket do
        allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
        Services.s3_client.put_object(key: "something.xml",
                                      bucket:,
                                      body: body_content)

        ["/sitemaps/something.xml", "/sitemaps/something"].each do |path|
          get path
          expect(last_response.status).to eq(200)
          expect(last_response.headers["Content-Type"]).to eq("application/xml")
          expect(last_response.headers["Cache-Control"]).to eq("public")
          expect(last_response.headers["Last-Modified"]).to eq(FakeS3::LAST_MODIFIED.httpdate)
          expect(last_response.body).to eq(body_content)
        end
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
end
