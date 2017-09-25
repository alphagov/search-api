require 'spec_helper'

RSpec.describe 'SitemapCleanupTest' do
  it "should_delete_old_sitemaps" do
    Dir.stub(:glob).and_return(%w{
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

    expect(FileUtils).to receive(:rm).with("sitemap_2015-03-04T01.xml")
    expect(FileUtils).to receive(:rm).with("sitemap_1_2015-03-04T01.xml")

    cleanup = SitemapCleanup.new('public')
    cleanup.delete_excess_sitemaps
  end

  it "should_delete_old_sitemaps_with_a_gap_in_days" do
    Dir.stub(:glob).and_return(%w{
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

    expect(FileUtils).to receive(:rm).with("sitemap_2015-03-03T01.xml")
    expect(FileUtils).to receive(:rm).with("sitemap_1_2015-03-03T01.xml")

    cleanup = SitemapCleanup.new('public')
    cleanup.delete_excess_sitemaps
  end
end
