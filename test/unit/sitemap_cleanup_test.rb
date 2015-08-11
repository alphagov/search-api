require "test_helper"
require "elasticsearch/sitemap"

class SitemapCleanupTest < MiniTest::Unit::TestCase
  def test_should_delete_old_sitemaps
    Dir.stubs(:glob).returns(%w{
      sitemap_2015-03-05T01.xml
      sitemap_1_2015-03-05T01.xml

      sitemap_2015-03-06T01.xml
      sitemap_1_2015-03-06T01.xml

      sitemap_2015-03-07T01.xml
      sitemap_1_2015-03-07T01.xml

      sitemap_2015-03-08T01.xml
      sitemap_1_2015-03-08T01.xml

      sitemap_2015-03-04T01.xml
      sitemap_1_2015-03-04T01.xml
    })

    FileUtils.expects(:rm).with("sitemap_2015-03-04T01.xml")
    FileUtils.expects(:rm).with("sitemap_1_2015-03-04T01.xml")

    cleanup = SitemapCleanup.new('public')
    cleanup.delete_excess_sitemaps
  end

  def test_should_delete_old_sitemaps_with_a_gap_in_days
    Dir.stubs(:glob).returns(%w{
      sitemap_2015-03-05T01.xml
      sitemap_1_2015-03-05T01.xml

      sitemap_2015-03-07T01.xml
      sitemap_1_2015-03-07T01.xml

      sitemap_2015-03-09T01.xml
      sitemap_1_2015-03-09T01.xml

      sitemap_2015-03-11T01.xml
      sitemap_1_2015-03-11T01.xml

      sitemap_2015-03-03T01.xml
      sitemap_1_2015-03-03T01.xml
    })

    FileUtils.expects(:rm).with("sitemap_2015-03-03T01.xml")
    FileUtils.expects(:rm).with("sitemap_1_2015-03-03T01.xml")

    cleanup = SitemapCleanup.new('public')
    cleanup.delete_excess_sitemaps
  end
end
