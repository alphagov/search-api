require "test_helper"
require "elasticsearch/sitemap"

class SitemapIndexTest < MiniTest::Unit::TestCase
  def test_should_generate_index_sitemap
    index_file = StringIO.new()
    File.stubs(:open).yields(index_file)
    sitemap = Sitemap.new('/foo')
    sitemaps = ['sitemap_test_1.xml', 'sitemap_test_2.xml']
    sitemap.write_index(sitemaps)
    doc = Nokogiri::XML(index_file.string)
    doc.css('sitemapindex > sitemap').zip(sitemaps) do |sitemap_xml, filename|
      assert sitemap_xml.css('loc').first.text.end_with? filename
    end
  end
end
