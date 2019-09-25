require "spec_helper"

RSpec.describe Sitemap, "Index" do
  it "should generate index sitemap" do
    index_file = StringIO.new
    allow(File).to receive(:open).and_yield(index_file)
    sitemap = described_class.new("/foo")
    sitemaps = ["sitemap_test_1.xml", "sitemap_test_2.xml"]
    sitemap.write_index(sitemaps)
    doc = Nokogiri::XML(index_file.string)
    doc.css("sitemapindex > sitemap").zip(sitemaps) do |sitemap_xml, filename|
      expect(sitemap_xml.css("loc").first.text).to match(/#{filename}$/)
    end
  end
end
