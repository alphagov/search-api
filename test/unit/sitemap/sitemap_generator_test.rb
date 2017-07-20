require "test_helper"
require "sitemap/sitemap"

class SitemapGeneratorTest < Minitest::Test
  def test_should_generate_sitemap
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml(['https://www.gov.uk/page', '/another-page', 'yet-another-page'])
    doc = Nokogiri::XML(sitemap_xml)
    urls = doc.css('url > loc').map(&:inner_html)
    assert_equal urls[0], 'https://www.gov.uk/page'
    assert_equal urls[1], 'http://www.dev.gov.uk/another-page'
    assert_equal urls[2], 'http://www.dev.gov.uk/yet-another-page'
  end
end
