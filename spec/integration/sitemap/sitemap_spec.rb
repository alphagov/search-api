require "spec_helper"

RSpec.describe "SitemapTest" do
  before do
    @path = "/tmp/#{SecureRandom.uuid}"
    @timestamp = Time.now.utc
    FileUtils.mkdir_p("#{@path}/sitemaps")
  end

  let(:generator) {
    double("generator")
  }

  let(:sitemap) do
    Sitemap.new(generator, @path)
  end

  after do
    FileUtils.rm_rf(@path)
  end

  it "creates symbolic links to the sitemap files" do
    filename = create_test_file
    link_name = "sitemap_1.xml"
    link_full_name = "#{@path}/sitemaps/sitemap_1.xml"
    sitemaps = { sitemaps: [[filename, link_name]], index: "" }
    allow(generator).to receive(:run).and_return(sitemaps)

    expect(File.exist?(link_name)).to eq(false)

    sitemap.generate_and_replace

    expect(File.symlink?(link_full_name)).to eq(true)
    expect(File.readlink(link_full_name)).to eq("#{@path}/sitemaps/#{filename}")
  end

  it "creates an index pointing to the symbolic links" do
    filename = create_test_file
    link_name = "sitemap_1.xml"
    index_filename = "sitemap_#{@timestamp.strftime('%FT%H')}.xml"
    sitemaps = { sitemaps: [[filename, link_name]], index: index_filename }
    allow(generator).to receive(:run).and_return(sitemaps)

    sitemap.generate_and_replace

    index_filename_path = "#{@path}/sitemaps/#{index_filename}"
    index_linkname_path = "#{@path}/sitemap.xml"

    expect(File.readlink(index_linkname_path)).to eq(index_filename_path)
  end

  it "does not cleanup the symbolic link files or linked files" do
    create_test_file("sitemap_1_2017-01-01T06.xml")
    create_test_file("sitemap_1_2017-01-02T06.xml")
    create_test_file("sitemap_1_2017-01-03T06.xml")
    create_test_file("sitemap_1_2017-01-04T06.xml")
    create_test_file("sitemap_1_2017-01-05T06.xml")
    create_test_file("sitemap_1_2017-01-06T06.xml")
    create_test_file("sitemap_2017-01-01T06.xml")

    File.symlink("#{@path}/sitemaps/sitemap_1_2017-01-06T06.xml", "#{@path}/sitemaps/sitemap_1.xml")
    File.symlink("#{@path}/sitemaps/sitemap_2017-01-01T06.xml", "#{@path}/sitemaps/sitemap.xml")

    sitemap.cleanup

    expect(File.exist?("#{@path}/sitemaps/sitemap_1_2017-01-01T06.xml")).to eq(false)
    expect(File.exist?("#{@path}/sitemaps/sitemap_1_2017-01-06T06.xml")).to eq(true)
    expect(File.exist?("#{@path}/sitemaps/sitemap_1.xml")).to eq(true)

    expect(File.exist?("#{@path}/sitemaps/sitemap_2017-01-01T06.xml")).to eq(true)
    expect(File.exist?("#{@path}/sitemaps/sitemap.xml")).to eq(true)
  end

  it "can overwrite existing links" do
    filename = create_test_file("sitemap_1_2017-01-01T06.xml")
    link_name = "sitemap_1.xml"
    index_filename = "sitemap_#{@timestamp.strftime('%FT%H')}.xml"
    sitemaps = { sitemaps: [[filename, link_name]], index: index_filename }
    allow(generator).to receive(:run).and_return(sitemaps)

    File.symlink("#{@path}/sitemaps/sitemap_1_2017-01-01T06.xml", "#{@path}/sitemap.xml")

    sitemap.generate_and_replace

    expect(File.readlink("#{@path}/sitemap.xml")).to eq("#{@path}/sitemaps/sitemap_#{@timestamp.strftime('%FT%H')}.xml")
  end

  def create_test_file(name = "#{SecureRandom.uuid}.xml")
    File.open("#{@path}/sitemaps/#{name}", "w+") { |f| f.puts "test" }
    name
  end
end
