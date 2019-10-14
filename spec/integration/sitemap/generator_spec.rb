require "spec_helper"

RSpec.describe Sitemap::Generator do
  let(:sitemap_writer) {
    double("sitemap_writer", write_sitemap: [], write_index: [], output_path: "")
  }

  let(:sitemap_uploader) {
    double("sitemap_uploader", upload: true)
  }

  let(:generator) {
    described_class.new(search_config, client, sitemap_writer, sitemap_uploader)
  }

  it "generates multiple sitemaps" do
    stub_const("Sitemap::Generator::SITEMAP_LIMIT", 2)
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

    expect(sitemap_writer).to receive(:write_sitemap).exactly(:twice) # sample_document.count + homepage / sitemap_limit rounded up

    documents = generator.batches_of_documents
    generator.create_sitemap_files(documents)
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

    expect(sitemap_writer).to receive(:write_sitemap).with(expected_xml, 1)

    documents = generator.batches_of_documents
    generator.create_sitemap_files(documents)
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

    expect(sitemap_writer).to receive(:write_sitemap).with(expected_xml, 1)

    documents = generator.batches_of_documents
    generator.create_sitemap_files(documents)
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

    expect(sitemap_writer).to receive(:write_sitemap).with(expected_xml, 1)

    documents = generator.batches_of_documents
    generator.create_sitemap_files(documents)
  end

private

  def add_sample_documents(docs, index_name: "government_test")
    docs.each do |sample_document|
      insert_document(index_name, sample_document)
    end
    commit_index index_name
  end
end
