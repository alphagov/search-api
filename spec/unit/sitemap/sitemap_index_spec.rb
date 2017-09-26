require 'spec_helper'

RSpec.describe 'SitemapIndexTest' do
  it "should_generate_index_sitemap" do
    index_file = StringIO.new
    File.stub(:open).and_yield(index_file)
    sitemap = Sitemap.new('/foo')
    sitemaps = ['sitemap_test_1.xml', 'sitemap_test_2.xml']
    sitemap.write_index(sitemaps)
    doc = Nokogiri::XML(index_file.string)
    doc.css('sitemapindex > sitemap').zip(sitemaps) do |sitemap_xml, filename|
      assert sitemap_xml.css('loc').first.text.end_with? filename
    end
  end
end
