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
      expect(last_request.env["govuk.prometheus_labels"][:search_api_endpoint]).to eq("sitemap")
    end
  end

  describe "get /sitemaps/:sitemap" do
    before do
      allow(Services).to receive(:s3_client).and_return(FakeS3.fake_s3_client)
    end

    context "with valid key" do
      before do
        Services.s3_client.put_object(key: "sitemap_1.xml",
                                      bucket:,
                                      body: body_content)
      end

      it "streams the sitemap XML from S3" do
        get "/sitemaps/sitemap_1.xml"

        expect(last_response.status).to eq(200)
        expect(last_response.headers["Content-Type"]).to eq("application/xml")
        expect(last_response.headers["Cache-Control"]).to eq("public")
        expect(last_response.headers["Last-Modified"]).to eq(FakeS3::LAST_MODIFIED.httpdate)
        expect(last_response.body).to eq(body_content)
      end

      it "sets endpoint as a prometheus label" do
        get "/sitemaps/sitemap_1.xml"
        expect(last_request.env["govuk.prometheus_labels"][:search_api_endpoint]).to eq("sitemap")
      end
    end

    context "when key is well formed but invalid" do
      it "cannot find the sitemap" do
        get "/sitemaps/sitemap_30000.xml"

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq("No such object")
      end
    end

    context "when key is badly formed" do
      it "halts and returns a 400" do
        bad_keys = ["anything.xml", "sitemap_1.xmlxEB", "soap"]

        bad_keys.each do |key|
          get "/sitemaps/#{key}"
          expect(last_response.status).to eq(400)
        end
      end
    end
  end
end
