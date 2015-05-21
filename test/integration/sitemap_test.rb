require "integration_test_helper"
require "app"
require "rest-client"
require "nokogiri"
require "elasticsearch/sitemap"

class SitemapTest < IntegrationTest

  def setup
    @index_names = %w(mainstream_test detailed_test government_test)
    stub_elasticsearch_settings
    enable_test_index_connections

    @index_names.each do |i|
      try_remove_test_index(i)
      create_test_index(i)
    end

    add_sample_documents
    commit_index
  end

  def teardown
    @index_names.each do |i| clean_index_group(i) end
  end

  def commit_index
    post "/commit", nil
  end

  def sample_document_attributes
    [
      {
        "title" => "Cheese in my face",
        "description" => "Hummus weevils",
        "format" => "answer",
        "link" => "/an-example-answer",
        "indexable_content" => "I like my badger: he is tasty and delicious"
      },
      {
        "title" => "Cheese on Ruby's face",
        "description" => "Ruby weevils",
        "format" => "answer",
        "link" => "/an-example-answer-rubylol",
        "indexable_content" => "I like my rubby badger: he is tasty and delicious"
      },
      {
        "title" => "Cheese on Python's face",
        "description" => "Python weevils",
        "format" => "answer",
        "link" => "/an-example-answer-pythonwin",
        "indexable_content" => "I like my badger: he is pythonic and delicious"
      },
      {
        "title" => "Cheese in my ears",
        "description" => "Wordpress weevils",
        "format" => "answer",
        "link" => "/an-example-answer-stuff",
        "indexable_content" => "I like my wordpress: says Joshua who is win"
      },
      {
        "title" => "Useful government information",
        "description" => "Government, government, government. Developers.",
        "format" => "answer",
        "link" => "/another-example-answer",
        "section" => "Crime",
        "indexable_content" => "Tax, benefits, roads and stuff"
      },
      {
        "title" => "External government information",
        "description" => "Government, government, government. Developers.",
        "format" => "recommended-link",
        "link" => "http://www.example.com/external-example-answer",
        "section" => "Crime",
        "indexable_content" => "Tax, benefits, roads and stuff"
      },
      {
        "title" => "Bad document missing a link field",
      },
      {
        "title" => "Some content from Inside Gov",
        "description" => "We list some inside gov results in the mainstream index.",
        "format" => "inside-government-link",
        "link" => "https://www.gov.uk/government/some-content",
        "section" => "Inside Government"
      }
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |sample_document|
      post "/documents", sample_document.to_json
      assert last_response.ok?
    end
  end

  def assert_result_links(*links)
    order = true
    if links[-1].is_a?(Hash)
      hash = links.pop
      order = hash[:order]
    end
    doc = Nokogiri::XML(last_response.body)
    paths = doc.css('loc').collect(&:text).map { |l| URI.parse(l).path }

    if order
      assert_equal links, paths
    else
      assert_equal links.sort, paths.sort
    end
  end

  def assert_no_link(link)
    doc = Nokogiri::XML(last_response.body)
    paths = doc.css('loc').collect(&:text).map { |l| URI.parse(l).path }

    assert ! paths.include?(link), "Found #{link} in sitemap"
  end

  def test_should_generate_multiple_sitemaps
    SitemapGenerator.stubs(:sitemap_limit).returns(2)
    generator = SitemapGenerator.new(search_server.content_indices)
    sitemap_xml = generator.sitemaps
    assert_equal 3, sitemap_xml.length
  end

  def test_should_not_include_recommended_links
    generator = SitemapGenerator.new(search_server.content_indices)
    sitemap_xml = generator.sitemaps
    assert_equal 1, sitemap_xml.length
    refute_includes sitemap_xml[0], "/external-example-answer"
  end

  def test_should_not_include_inside_government_links
    generator = SitemapGenerator.new(search_server.content_indices)
    sitemap_xml = generator.sitemaps
    assert_equal 1, sitemap_xml.length
    refute_includes sitemap_xml[0],  "/government/some-content"
  end
end
