require "spec_helper"

RSpec.describe SitemapCleanup do
  it "should delete old sitemaps" do
    allow(Dir).to receive(:glob).and_return(%w{
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

    cleanup = described_class.new("public")
    cleanup.delete_excess_sitemaps
  end

  it "should delete old sitemaps with a gap in days" do
    allow(Dir).to receive(:glob).and_return(%w{
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

    cleanup = described_class.new("public")
    cleanup.delete_excess_sitemaps
  end
end
