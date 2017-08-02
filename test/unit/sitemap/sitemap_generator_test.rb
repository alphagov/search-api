require "test_helper"
require "sitemap/sitemap"

class SitemapGeneratorTest < Minitest::Test
  def test_should_generate_sitemap
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml([
      build_document('https://www.gov.uk/page'),
      build_document('/another-page'),
      build_document('yet-another-page'),
    ])

    doc = Nokogiri::XML(sitemap_xml)
    urls = doc.css('url > loc').map(&:inner_html)
    assert_equal "https://www.gov.uk/page", urls[0]
    assert_equal "http://www.dev.gov.uk/another-page", urls[1]
    assert_equal "http://www.dev.gov.uk/yet-another-page", urls[2]
  end

  def test_links_should_include_timestamps
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml([
      build_document('/some-page', timestamp: "2014-01-28T14:41:50+00:00"),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    assert_equal "2014-01-28T14:41:50+00:00", pages[0].css("lastmod").text
  end

  def test_missing_timestamps_are_ignored
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml([
      build_document('/page-without-date'),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    assert_page_has_no_lastmod(pages[0])
  end

  def test_page_priority_is_document_priority
    sitemap = SitemapGenerator.new('')

    document = build_document('/some-path')
    document.stubs(:priority).returns(0.48)

    sitemap_xml = sitemap.generate_xml([document])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    assert_equal("0.48", pages[0].css("priority").text)
  end

  def build_document(url, timestamp: nil, is_withdrawn: nil)
    attributes = {
      "link" => url,
      "_type" => "some_type",
    }
    attributes["public_timestamp"] = timestamp if timestamp
    attributes["is_withdrawn"] = is_withdrawn if !is_withdrawn.nil?

    SitemapPresenter.new(
      Document.new(sample_field_definitions, attributes),
      FormatBoostCalculator.new
    )
  end

  def assert_page_has_no_lastmod(page)
    last_modified = page.css("lastmod").text
    assert last_modified.empty?,
      "Page in sitemap has unexpected 'lastmod' date: '#{last_modified}'"
  end
end
