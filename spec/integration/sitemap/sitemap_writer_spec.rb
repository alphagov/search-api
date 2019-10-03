require "spec_helper"

RSpec.describe "SitemapTest" do
  before do
    @path = "/tmp/#{SecureRandom.uuid}"
    @timestamp = Time.now.utc
    FileUtils.mkdir_p("#{@path}/sitemaps")
  end

  after do
    FileUtils.rm_rf(@path)
  end

  let(:writer) {
    SitemapWriter.new(@path, @timestamp)
  }

  it "creates a sitemap file" do
    writer.write_sitemap("some xml", 1)

    expect(File.read("#{@path}/sitemaps/sitemap_1_#{@timestamp.strftime('%FT%H')}.xml")).to eq "some xml"
  end

  it "creates an index pointing to the symbolic links" do
    sitemap_filenames = ["sitemap_1.xml", "sitemap_2.xml"]

    writer.write_index(sitemap_filenames)

    expected_xml = <<~XML
      <?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_1.xml</loc>
          <lastmod>#{@timestamp.strftime("%FT%T%:z")}</lastmod>
        </sitemap>
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_2.xml</loc>
          <lastmod>#{@timestamp.strftime("%FT%T%:z")}</lastmod>
        </sitemap>
      </sitemapindex>
    XML

    index_filename = "sitemap_#{@timestamp.strftime('%FT%H')}.xml"
    index_filename_path = "#{@path}/sitemaps/#{index_filename}"

    expect(File.read(index_filename_path)).to eq(expected_xml)
  end
end
