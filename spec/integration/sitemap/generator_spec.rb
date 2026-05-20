require "spec_helper"
require "sitemap/uploader"

RSpec.describe Sitemap::Generator do
  let(:sitemap_uploader) { double("sitemap_uploader", upload: true) }
  let(:generator) { described_class.new(search_config, sitemap_uploader, timestamp) }
  let(:index_name) { SearchConfig.govuk_index_name }
  let(:timestamp) { Time.now.utc }

  it "generates and uploads multiple sitemaps" do
    stub_const("Sitemap::Generator::SITEMAP_LIMIT", 2)

    3.times { commit_document(index_name, build(:document, :all)) }
    generator.run

    expect(sitemap_uploader).to have_received(:upload).exactly(3).times # sample_document.count + homepage / sitemap_limit rounded up
  end

  it "only includes migrated formats from govuk" do
    commit_document(index_name,
                    build(:document, link: "/an-example-answer",
                                     public_timestamp: "2017-07-01T12:41:34+00:00",
                                     format: "answer"))
    commit_document(index_name,
                    build(:document, link: "/an-unmigrated-answer",
                                     format: "not-migrated-format"))

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>http://www.dev.gov.uk/</loc>
          <priority>0.5</priority>
        </url>
        <url>
          <loc>http://www.dev.gov.uk/an-example-answer</loc>
          <lastmod>2017-07-01T12:41:34+00:00</lastmod>
          <priority>0.5</priority>
        </url>
      </urlset>
    HEREDOC

    generator.run

    expect(sitemap_uploader).to have_received(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")
  end

  it "adds a sitemap with homepage and document" do
    commit_document(index_name,
                    build(:document, link: "/an-example-answer",
                                     public_timestamp: "2017-07-01T12:41:34+00:00"))

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>http://www.dev.gov.uk/</loc>
          <priority>0.5</priority>
        </url>
        <url>
          <loc>http://www.dev.gov.uk/an-example-answer</loc>
          <lastmod>2017-07-01T12:41:34+00:00</lastmod>
          <priority>0.5</priority>
        </url>
      </urlset>
    HEREDOC

    generator.run

    expect(sitemap_uploader).to have_received(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")
  end

  it "does not include recommended links" do
    commit_document(index_name,
                    build(:document,
                          link: "/an-example-answer",
                          format: "recommended-link",
                          public_timestamp: "2017-07-01T12:41:34+00:00"))

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>http://www.dev.gov.uk/</loc>
          <priority>0.5</priority>
        </url>
      </urlset>
    HEREDOC

    generator.run

    expect(sitemap_uploader).to have_received(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")
  end

  it "includes parts of documents" do
    commit_document(index_name,
                    build(:document,
                          link: "/an-example-answer",
                          public_timestamp: "2017-07-01T12:41:34+00:00",
                          parts: [
                            {
                              "slug": "hummus-weevils",
                              "body": "I like my badger",
                            },
                            {
                              "slug": "tasty-badger",
                              "body": "he is tasty and delicious",
                            },
                          ]))

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>http://www.dev.gov.uk/</loc>
          <priority>0.5</priority>
        </url>
        <url>
          <loc>http://www.dev.gov.uk/an-example-answer/hummus-weevils</loc>
          <lastmod>2017-07-01T12:41:34+00:00</lastmod>
          <priority>0.375</priority>
        </url>
        <url>
          <loc>http://www.dev.gov.uk/an-example-answer/tasty-badger</loc>
          <lastmod>2017-07-01T12:41:34+00:00</lastmod>
          <priority>0.375</priority>
        </url>
        <url>
          <loc>http://www.dev.gov.uk/an-example-answer</loc>
          <lastmod>2017-07-01T12:41:34+00:00</lastmod>
          <priority>0.5</priority>
        </url>
      </urlset>
    HEREDOC

    generator.run

    expect(sitemap_uploader).to have_received(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")
  end

  it "generates and uploads the sitemap index" do
    stub_const("Sitemap::Generator::SITEMAP_LIMIT", 2)
    commit_document(index_name, build(:document, :all))
    commit_document(index_name, build(:document, :all))

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_1.xml</loc>
          <lastmod>#{timestamp.strftime('%FT%T%:z')}</lastmod>
        </sitemap>
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_2.xml</loc>
          <lastmod>#{timestamp.strftime('%FT%T%:z')}</lastmod>
        </sitemap>
      </sitemapindex>
    HEREDOC

    generator.run

    expect(sitemap_uploader).to have_received(:upload).with(file_content: expected_xml, file_name: "sitemap.xml").exactly(:once)
  end
end
