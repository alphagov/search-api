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
    assert_equal urls[0], 'https://www.gov.uk/page'
    assert_equal urls[1], 'http://www.dev.gov.uk/another-page'
    assert_equal urls[2], 'http://www.dev.gov.uk/yet-another-page'
  end

  def test_links_should_include_timestamps
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml([
      build_document('/page-with-datetime', "2014-01-28T14:41:50+00:00"),
      build_document('/page-with-date', "2017-07-12"),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    assert_equal "2014-01-28T14:41:50+00:00", pages[0].css("lastmod").text
    assert_equal "2017-07-12", pages[1].css("lastmod").text
  end

  def test_missing_timestamps_are_ignored
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml([
      build_document('/page-without-date'),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    assert_page_has_no_lastmod(pages[0])
  end

  def test_invalid_timestamps_are_ignored
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml([
      build_document('/page-1', ""),
      build_document('/page-2', "not-a-date"),
      build_document('/page-3', "01-01-2017"),
    ])

    pages = Nokogiri::XML(sitemap_xml).css("url")

    assert_page_has_no_lastmod(pages[0])
    assert_page_has_no_lastmod(pages[1])
    assert_page_has_no_lastmod(pages[2])
  end

  def build_document(url, timestamp = nil)
    attributes = {
      "link" => url,
      "_type" => "some_type",
    }
    attributes["public_timestamp"] = timestamp if timestamp

    Document.new(sample_field_definitions, attributes)
  end

  def assert_page_has_no_lastmod(page)
    last_modified = page.css("lastmod").text
    assert last_modified.empty?,
      "Page in sitemap has unexpected 'lastmod' date: '#{last_modified}'"
  end
end
