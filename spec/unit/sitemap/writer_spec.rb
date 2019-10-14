require "spec_helper"

RSpec.describe Sitemap::Writer, "Index" do
  it "generates sitemap" do
    sitemap_file = StringIO.new
    sitemap_number = 5
    allow(File).to receive(:open).and_yield(sitemap_file)
    allow(FileUtils).to receive(:mkdir_p)
    timestamp = Time.now.utc
    sitemap_writer = described_class.new("/directory", timestamp)

    sitemap = sitemap_writer.write_sitemap("xml content", sitemap_number)

    expect(sitemap_file.string).to eq "xml content"
    expect(sitemap.first).to eq "sitemap_#{sitemap_number}_#{timestamp.strftime('%FT%H')}.xml"
    expect(sitemap.last).to eq "sitemap_5.xml"
  end

  it "generates index sitemap" do
    index_file = StringIO.new
    allow(File).to receive(:open).and_yield(index_file)
    allow(FileUtils).to receive(:mkdir_p)
    sitemap_writer = described_class.new("/directory", Time.now.utc)
    sitemaps = ["sitemap_test_1.xml", "sitemap_test_2.xml"]

    sitemap_writer.write_index(sitemaps)

    doc = Nokogiri::XML(index_file.string)
    doc.css("sitemapindex > sitemap").zip(sitemaps) do |sitemap_xml, filename|
      expect(sitemap_xml.css("loc").first.text).to match(/#{filename}$/)
    end
  end
end
