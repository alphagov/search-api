require "spec_helper"

RSpec.describe "SitemapTest" do
  before do
    @path = "/tmp/#{SecureRandom.uuid}"
    FileUtils.mkdir_p("#{@path}/sitemaps")
  end

  after do
    FileUtils.rm_rf(@path)
  end

  it "it creates symbolic links to the sitemap files" do
    filename = create_test_file
    link_name = "sitemap_1.xml"
    link_full_name = "#{@path}/sitemaps/sitemap_1.xml"
    allow_any_instance_of(SitemapWriter).to receive(:write_sitemaps).and_return([[filename, link_name]])

    expect(File.exist?(link_name)).to eq(false)

    Sitemap.new(@path).generate_and_replace(double(:content_indices)) # rubocop:disable RSpec/VerifiedDoubles

    expect(File.symlink?(link_full_name)).to eq(true)
    expect(File.readlink(link_full_name)).to eq("#{@path}/sitemaps/#{filename}")
  end

  it "it creates an index pointing to the symbolic links" do
    filename = create_test_file
    link_name = "sitemap_1.xml"
    allow_any_instance_of(SitemapWriter).to receive(:write_sitemaps).and_return([[filename, link_name]])

    time = Time.now.utc
    Sitemap.new(@path, time).generate_and_replace(double(:content_indices)) # rubocop:disable RSpec/VerifiedDoubles

    index_filename = "#{@path}/sitemaps/sitemap_#{time.strftime('%FT%H')}.xml"
    index_linkname = "#{@path}/sitemap.xml"

    expected_xml = <<~XML
      <?xml version=\"1.0\" encoding=\"UTF-8\"?>
      <sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_1.xml</loc>
          <lastmod>#{time.strftime("%FT%T%:z")}</lastmod>
        </sitemap>
      </sitemapindex>
    XML

    expect(File.read(index_filename)).to eq(expected_xml)
    expect(File.readlink(index_linkname)).to eq(index_filename)
  end

  it "it does not cleanup the symbolic link files or linked files" do
    create_test_file("sitemap_1_2017-01-01T06.xml")
    create_test_file("sitemap_1_2017-01-02T06.xml")
    create_test_file("sitemap_1_2017-01-03T06.xml")
    create_test_file("sitemap_1_2017-01-04T06.xml")
    create_test_file("sitemap_1_2017-01-05T06.xml")
    create_test_file("sitemap_1_2017-01-06T06.xml")
    create_test_file("sitemap_2017-01-01T06.xml")
    File.symlink("#{@path}/sitemaps/sitemap_1_2017-01-06T06.xml", "#{@path}/sitemaps/sitemap_1.xml")
    File.symlink("#{@path}/sitemaps/sitemap_2017-01-01T06.xml", "#{@path}/sitemaps/sitemap.xml")

    Sitemap.new(@path).cleanup

    expect(File.exist?("#{@path}/sitemaps/sitemap_1_2017-01-01T06.xml")).to eq(false)
    expect(File.exist?("#{@path}/sitemaps/sitemap_1_2017-01-06T06.xml")).to eq(true)
    expect(File.exist?("#{@path}/sitemaps/sitemap_1.xml")).to eq(true)

    expect(File.exist?("#{@path}/sitemaps/sitemap_2017-01-01T06.xml")).to eq(true)
    expect(File.exist?("#{@path}/sitemaps/sitemap.xml")).to eq(true)
  end

  it "it can overwrite existing links" do
    create_test_file("sitemap_1_2017-01-01T06.xml")
    filename =  create_test_file("sitemap_1_2017-01-02T06.xml")

    link_name = "sitemap_1.xml"
    allow_any_instance_of(SitemapWriter).to receive(:write_sitemaps).and_return([[filename, link_name]])

    time = Time.now.utc
    File.symlink("#{@path}/sitemaps/sitemap_1_2017-01-01T06.xml", "#{@path}/sitemap.xml")

    Sitemap.new(@path, time).generate_and_replace(double)

    expect(File.readlink("#{@path}/sitemap.xml")).to eq("#{@path}/sitemaps/sitemap_#{time.strftime('%FT%H')}.xml")
  end

  def create_test_file(name = "#{SecureRandom.uuid}.xml")
    File.open("#{@path}/sitemaps/#{name}", "w+") { |f| f.puts "test" }
    name
  end
end
