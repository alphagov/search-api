require "spec_helper"

RSpec.describe SitemapGenerator do
  before do
    allow_any_instance_of(LegacyClient::IndexForSearch).to receive(:real_index_names).and_return(%w(govuk_test))
  end


  it "generates sitemap" do
    sitemap = described_class.new(SearchConfig.default_instance)

    sitemap_xml = sitemap.generate_xml([
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

  it "links should include timestamps" do
    sitemap = described_class.new(SearchConfig.default_instance)

    sitemap_xml = sitemap.generate_xml([
      build_document("/some-page", timestamp: "2014-01-28T14:41:50+00:00"),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    expect(pages[0].css("lastmod").text).to eq("2014-01-28T14:41:50+00:00")
  end

  it "missing timestamps are ignored" do
    sitemap = described_class.new(SearchConfig.default_instance)

    sitemap_xml = sitemap.generate_xml([
      build_document("/page-without-date"),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    expect_page_has_no_lastmod(pages[0])
  end

  it "page priority is document priority" do
    sitemap = described_class.new(SearchConfig.default_instance)

    document = build_document("/some-path")
    allow(document).to receive(:priority).and_return(0.48)

    sitemap_xml = sitemap.generate_xml([document])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    expect(pages[0].css("priority").text).to eq("0.48")
  end

  def build_document(url, timestamp: nil, is_withdrawn: nil)
    attributes = {
      "link" => url,
      "document_type" => "some_type",
    }
    attributes["public_timestamp"] = timestamp if timestamp
    attributes["is_withdrawn"] = is_withdrawn if !is_withdrawn.nil?

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
