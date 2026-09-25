require "spec_helper"

RSpec.describe "SitemapTest", type: :request do
  let(:bucket) { "test-bucket" }
  let(:body_content) do
    <<~XML
      <urlset>
        <url><loc>https://example.com/</loc></url>
        <url><loc>https://example.com/about</loc></url>
      </urlset>
    XML
  end

  around do |example|
    ClimateControl.modify AWS_S3_SITEMAPS_BUCKET_NAME: bucket do
      example.run
    end
  end

  describe "get /sitemap.xml" do
    before do
      allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
      Services.s3_client.put_object(key: "sitemap.xml",
                                    bucket:,
                                    body: body_content)
      get "/sitemap.xml"
    end

    it "streams the sitemap XML from S3" do
      expect(last_response.status).to eq(200)
      expect(last_response.headers["Content-Type"]).to eq("application/xml")
      expect(last_response.headers["Cache-Control"]).to eq("public")
      expect(last_response.headers["Last-Modified"]).to eq(FakeS3::LAST_MODIFIED.httpdate)
      expect(last_response.body).to eq(body_content)
    end

    it "sets endpoint as a prometheus label" do
      expect(last_request.env["govuk.prometheus_labels"][:endpoint]).to eq("sitemap")
    end
  end

  describe "get /sitemaps/:sitemap" do
    before do
      allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
    end

    it "sets endpoint as a prometheus label" do
      get "/sitemaps/something.xml"
      expect(last_request.env["govuk.prometheus_labels"][:endpoint]).to eq("sitemap")
    end

    context "with valid key" do
      before do
        Services.s3_client.put_object(key: "something.xml",
                                      bucket:,
                                      body: body_content)
      end

      it "streams the sitemap XML from S3" do
        get "/sitemaps/something.xml"

        expect(last_response.status).to eq(200)
        expect(last_response.headers["Content-Type"]).to eq("application/xml")
        expect(last_response.headers["Cache-Control"]).to eq("public")
        expect(last_response.headers["Last-Modified"]).to eq(FakeS3::LAST_MODIFIED.httpdate)
        expect(last_response.body).to eq(body_content)
      end
    end

    context "with invalid key" do
      it "cannot find the sitemap" do
        get "/sitemaps/something_else.xml"

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq("No such object")
      end
    end
  end
end
