require 'integration_test_helper'

class SitemapTest < IntegrationTest
  def setup
    super
    @path = "/tmp/#{SecureRandom.uuid}"
    FileUtils.mkdir_p("#{@path}/sitemaps")
  end

  def teardown
    super
    FileUtils.rm_rf(@path)
  end

  def test_it_creates_symbolic_links_to_the_sitemap_files
    filename = create_test_file
    link_name = "sitemap_1.xml"
    link_full_name = "#{@path}/sitemaps/sitemap_1.xml"
    SitemapWriter.any_instance.stubs(:write_sitemaps).returns([[filename, link_name]])

    assert_equal File.exist?(link_name), false

    Sitemap.new(@path).generate(stub(:content_indices))

    assert_equal File.symlink?(link_full_name), true
    assert_equal File.readlink(link_full_name), "#{@path}/sitemaps/#{filename}"
  end

  def test_it_creates_an_index_pointing_to_the_symbolic_links
    filename = create_test_file
    link_name = "sitemap_1.xml"
    SitemapWriter.any_instance.stubs(:write_sitemaps).returns([[filename, link_name]])

    time = Time.now.utc
    Sitemap.new(@path, time).generate(stub(:content_indices))

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

    assert_equal File.read(index_filename), expected_xml
    assert_equal File.readlink(index_linkname), index_filename
  end

  def test_it_does_not_cleanup_the_symbolic_link_files_or_linked_files
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

    assert_equal File.exist?("#{@path}/sitemaps/sitemap_1_2017-01-01T06.xml"), false
    assert_equal File.exist?("#{@path}/sitemaps/sitemap_1_2017-01-06T06.xml"), true
    assert_equal File.exist?("#{@path}/sitemaps/sitemap_1.xml"), true

    assert_equal File.exist?("#{@path}/sitemaps/sitemap_2017-01-01T06.xml"), true
    assert_equal File.exist?("#{@path}/sitemaps/sitemap.xml"), true
  end

  def create_test_file(name = "#{SecureRandom.uuid}.xml")
    File.open("#{@path}/sitemaps/#{name}", 'w+') { |f| f.puts 'test' }
    name
  end
end
