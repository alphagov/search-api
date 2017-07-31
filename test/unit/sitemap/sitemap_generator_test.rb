require "test_helper"
require "sitemap/sitemap"

class SitemapGeneratorTest < Minitest::Test
  def test_should_generate_sitemap
    sitemap = SitemapGenerator.new('')

    sitemap_xml = sitemap.generate_xml([
      document_with_url('https://www.gov.uk/page'),
      document_with_url('/another-page'),
      document_with_url('yet-another-page'),
    ])

    doc = Nokogiri::XML(sitemap_xml)
    urls = doc.css('url > loc').map(&:inner_html)
    assert_equal urls[0], 'https://www.gov.uk/page'
    assert_equal urls[1], 'http://www.dev.gov.uk/another-page'
    assert_equal urls[2], 'http://www.dev.gov.uk/yet-another-page'
  end

  def document_with_url(url)
    attributes = {
      "link" => url,
      "_type" => "some_type",
    }

    Document.new(sample_field_definitions, attributes)
  end
end
