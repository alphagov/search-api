require "spec_helper"
require "sitemap/uploader"

RSpec.describe Sitemap::Generator do
  before do
    @timestamp = Time.now.utc
    stub_const("Sitemap::Generator::SCROLL_BATCH_SIZE", 1)
    stub_const("Sitemap::Generator::SITEMAP_LIMIT", 2)
  end

  let(:sitemap_uploader) do
    double("sitemap_uploader", upload: true)
  end

  let(:generator) do
    described_class.new(search_config, sitemap_uploader, @timestamp)
  end

  it "generates and uploads multiple sitemaps" do
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00",
        },
        {
          "title" => "Cheese on Ruby's face",
          "description" => "Ruby weevils",
          "format" => "answer",
          "link" => "/an-example-answer-rubylol",
          "indexable_content" => "I like my ruby badger: he is tasty and delicious",
        },
        {
          "title" => "Cheese on Python's face",
          "description" => "Python weevils",
          "format" => "answer",
          "link" => "/an-example-answer-pythonwin",
          "indexable_content" => "I like my badger: he is pythonic and delicious",
        },
      ],
      index_name: "govuk_test",
    )

    expect(sitemap_uploader).to receive(:upload).exactly(3).times # sample_document.count + homepage / sitemap_limit rounded up

    generator.run
  end

  it "does not include migrated formats from government" do
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00",
        },
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "not-migrated-format",
          "link" => "/another-example-answer",
          "indexable_content" => "I like my cat: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00",
        },
      ],
      index_name: "government_test",
    )

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>http://www.dev.gov.uk/</loc>
          <priority>0.5</priority>
        </url>
        <url>
          <loc>http://www.dev.gov.uk/another-example-answer</loc>
          <lastmod>2017-07-01T12:41:34+00:00</lastmod>
          <priority>0.5</priority>
        </url>
      </urlset>
    HEREDOC

    expect(sitemap_uploader).to receive(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")

    generator.run
  end

  it "includes homepage" do
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "cool-format",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00",
        },
      ],
      index_name: "government_test",
    )

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

    expect(sitemap_uploader).to receive(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")

    generator.run
  end

  it "does not include recommended links" do
    add_sample_documents(
      [
        {
          "title" => "External government information",
          "description" => "Government, government, government. Developers.",
          "format" => "recommended-link",
          "link" => "http://www.example.com/external-example-answer",
          "indexable_content" => "Tax, benefits, roads and stuff",
        },
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "unfiltered-format",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00",
        },
      ],
      index_name: "government_test",
    )

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

    expect(sitemap_uploader).to receive(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")

    generator.run
  end

  it "includes parts of documents" do
    stub_const("Sitemap::Generator::SITEMAP_LIMIT", 4)

    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00",
          "parts" => [
            {
              "slug": "hummus-weevils",
              "title": "Hummus weevils",
              "body": "I like my badger",
            },
            {
              "slug": "tasty-badger",
              "title": "Tasty badger",
              "body": "he is tasty and delicious",
            },
          ],
        },
      ],
      index_name: "govuk_test",
    )

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

    expect(sitemap_uploader).to receive(:upload).with(file_content: expected_xml, file_name: "sitemap_1.xml")

    generator.run
  end

  it "generates and uploads the sitemap index" do
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00",
        },
        {
          "title" => "Cheese on Ruby's face",
          "description" => "Ruby weevils",
          "format" => "answer",
          "link" => "/an-example-answer-rubylol",
          "indexable_content" => "I like my ruby badger: he is tasty and delicious",
        },
        {
          "title" => "Cheese on Python's face",
          "description" => "Python weevils",
          "format" => "answer",
          "link" => "/an-example-answer-pythonwin",
          "indexable_content" => "I like my badger: he is pythonic and delicious",
        },
      ],
      index_name: "govuk_test",
    )

    expected_xml = <<~HEREDOC
      <?xml version="1.0" encoding="UTF-8"?>
      <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_1.xml</loc>
          <lastmod>#{@timestamp.strftime('%FT%T%:z')}</lastmod>
        </sitemap>
        <sitemap>
          <loc>http://www.dev.gov.uk/sitemaps/sitemap_2.xml</loc>
          <lastmod>#{@timestamp.strftime('%FT%T%:z')}</lastmod>
        </sitemap>
      </sitemapindex>
    HEREDOC

    expect(sitemap_uploader).to receive(:upload).with(file_content: expected_xml, file_name: "sitemap.xml").exactly(:once)

    generator.run
  end

private

  def add_sample_documents(docs, index_name: "government_test")
    docs.each do |sample_document|
      insert_document(index_name, sample_document)
    end
    commit_index index_name
  end
end
