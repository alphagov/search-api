require 'spec_helper'

RSpec.describe 'SitemapGeneratorTest', tags: ['integration'] do

  it "should_generate_multiple_sitemaps" do
    allow(SitemapGenerator).to receive(:sitemap_limit).and_return(2)
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00"
        },
        {
          "title" => "Cheese on Ruby's face",
          "description" => "Ruby weevils",
          "format" => "answer",
          "link" => "/an-example-answer-rubylol",
          "indexable_content" => "I like my ruby badger: he is tasty and delicious"
        },
        {
          "title" => "Cheese on Python's face",
          "description" => "Python weevils",
          "format" => "answer",
          "link" => "/an-example-answer-pythonwin",
          "indexable_content" => "I like my badger: he is pythonic and delicious"
        },
      ],
      index_name: "govuk_test"
    )

    generator = SitemapGenerator.new(SearchConfig.instance)
    sitemap_xml = generator.sitemaps

    expected_sitemap_count = 2 # sample_document.count + homepage / sitemap_limit rounded up
    assert_equal expected_sitemap_count, sitemap_xml.length
  end

  it "does_not_include_migrated_formats_from_mainstream" do
    allow(SitemapGenerator).to receive(:sitemap_limit).and_return(2)
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00"
        },
      ],
      index_name: "mainstream_test"
    )
    generator = SitemapGenerator.new(SearchConfig.instance)
    sitemap_xml = generator.sitemaps
    assert_equal 1, sitemap_xml.length

    refute_includes sitemap_xml[0], "/an-example-answer"
  end

  it "should_include_homepage" do
    generator = SitemapGenerator.new(SearchConfig.instance)
    sitemap_xml = generator.sitemaps

    pages = Nokogiri::XML(sitemap_xml[0])
      .css("url")
      .select { |item| item.css("loc").text == "http://www.dev.gov.uk/" }

    assert_equal 1, pages.count
    assert_equal "0.5", pages[0].css("priority").text
  end

  it "should_not_include_recommended_links" do
    generator = SitemapGenerator.new(SearchConfig.instance)
    add_sample_documents(
      [
        {
          "title" => "External government information",
          "description" => "Government, government, government. Developers.",
          "format" => "recommended-link",
          "link" => "http://www.example.com/external-example-answer",
          "indexable_content" => "Tax, benefits, roads and stuff"
        },
      ],
      index_name: 'government_test'
    )

    sitemap_xml = generator.sitemaps

    assert_equal 1, sitemap_xml.length

    refute_includes sitemap_xml[0], "/external-example-answer"
  end

  it "should_not_include_inside_government_links" do
    generator = SitemapGenerator.new(SearchConfig.instance)
    add_sample_documents(
      [
        {
          "title" => "Some content from Inside Gov",
          "description" => "We list some inside gov results in the mainstream index.",
          "format" => "inside-government-link",
          "link" => "https://www.gov.uk/government/some-content",
        },
      ],
      index_name: 'government_test'
    )

    sitemap_xml = generator.sitemaps

    assert_equal 1, sitemap_xml.length
    refute_includes sitemap_xml[0], "/government/some-content"
  end

  it "links_should_include_timestamps" do
    generator = SitemapGenerator.new(SearchConfig.instance)
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00"
        },
      ],
      index_name: 'govuk_test'
    )

    sitemap_xml = generator.sitemaps

    pages = Nokogiri::XML(sitemap_xml[0])
      .css("url")
      .select { |item| item.css("loc").text == "http://www.dev.gov.uk/an-example-answer" }

    assert_equal 1, pages.count
    assert_equal "2017-07-01T12:41:34+00:00", pages[0].css("lastmod").text
  end

  it "links_should_include_priorities" do
    generator = SitemapGenerator.new(SearchConfig.instance)
    add_sample_documents(
      [
        {
          "title" => "Cheese in my face",
          "description" => "Hummus weevils",
          "format" => "answer",
          "link" => "/an-example-answer",
          "indexable_content" => "I like my badger: he is tasty and delicious",
          "public_timestamp" => "2017-07-01T12:41:34+00:00"
        },
      ],
      index_name: 'govuk_test'
    )

    sitemap_xml = generator.sitemaps

    pages = Nokogiri::XML(sitemap_xml[0])
      .css("url")
      .select { |item| item.css("loc").text == "http://www.dev.gov.uk/an-example-answer" }

    assert_equal 1, pages.count
    assert_includes 0..10, pages[0].css("priority").text.to_i
  end

private

  def add_sample_documents(docs, index_name: 'mainstream_test')
    docs.each do |sample_document|
      insert_document(index_name, sample_document)
    end
    commit_index index_name
  end
end
