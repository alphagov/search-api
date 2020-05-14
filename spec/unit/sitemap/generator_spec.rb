require "spec_helper"

RSpec.describe Sitemap::Generator do
  before do
    allow_any_instance_of(LegacyClient::IndexForSearch).to receive(:real_index_names).and_return(%w[govuk_test])
    @timestamp = Time.now.utc
  end

  let(:sitemap_generator) do
    sitemap_uploader = double("uploader")

    described_class.new(
      SearchConfig.default_instance,
      sitemap_uploader,
      @timestamp,
    )
  end

  it "generates sitemap" do
    sitemap_xml = sitemap_generator.generate_sitemap_xml([
      build_document("https://www.gov.uk/page"),
      build_document("/another-page"),
      build_document("yet-another-page"),
    ])

    doc = Nokogiri::XML(sitemap_xml)
    urls = doc.css("url > loc").map(&:inner_html)
    expect(urls[0]).to eq("https://www.gov.uk/page")
    expect(urls[1]).to eq("http://www.dev.gov.uk/another-page")
    expect(urls[2]).to eq("http://www.dev.gov.uk/yet-another-page")
  end

  it "generates a sitemap index" do
    sitemaps = ["sitemap_1.xml", "sitemap_2.xml"]

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_1.xml</loc>
          <lastmod>#{@timestamp.strftime('%FT%T%:z')}</lastmod>
        </sitemap>
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_2.xml</loc>
          <lastmod>#{@timestamp.strftime('%FT%T%:z')}</lastmod>
        </sitemap>
      </sitemapindex>
    HEREDOC

    expect(sitemap_generator.generate_sitemap_index_xml(sitemaps)).to eql(expected_xml)
  end

  it "links should include timestamps" do
    sitemap_xml = sitemap_generator.generate_sitemap_xml([
      build_document("/some-page", timestamp: "2014-01-28T14:41:50+00:00"),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    expect(pages[0].css("lastmod").text).to eq("2014-01-28T14:41:50+00:00")
  end

  it "missing timestamps are ignored" do
    sitemap_xml = sitemap_generator.generate_sitemap_xml([
      build_document("/page-without-date"),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    expect_page_has_no_lastmod(pages[0])
  end

  it "page priority is document priority" do
    document = build_document("/some-path")
    allow(document).to receive(:priority).and_return(0.48)

    sitemap_xml = sitemap_generator.generate_sitemap_xml([document])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    expect(pages[0].css("priority").text).to eq("0.48")
  end

  def build_document(url, timestamp: nil, is_withdrawn: nil)
    attributes = {
      "link" => url,
      "document_type" => "some_type",
    }
    attributes["public_timestamp"] = timestamp if timestamp
    attributes["is_withdrawn"] = is_withdrawn unless is_withdrawn.nil?

    SitemapPresenter.new(
      attributes,
      PropertyBoostCalculator.new,
    )
  end

  def expect_page_has_no_lastmod(page)
    last_modified = page.css("lastmod").text
    expect(last_modified).to be_empty, "Page in sitemap has unexpected 'lastmod' date: '#{last_modified}'"
  end
end
