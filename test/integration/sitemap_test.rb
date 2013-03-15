require "integration_test_helper"
require "app"
require "rest-client"
require "nokogiri"

class SitemapTest < IntegrationTest

  def setup
    @index_names = %w(mainstream_test detailed_test government_test)
    stub_elasticsearch_settings(@index_names)
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
      post "/documents", MultiJson.encode(sample_document)
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

  def test_should_return_a_sitemap
    get "/sitemap.xml"
    assert last_response.headers["Content-Type"].include?("application/xml")
    assert last_response.ok?
    assert_result_links "/", "/an-example-answer", "/another-example-answer", order: false
  end

  def test_should_not_include_recommended_links
    get "/sitemap.xml"
    assert last_response.headers["Content-Type"].include?("application/xml")
    assert last_response.ok?
    assert_no_link "/external-example-answer"
  end

  def test_should_not_include_inside_government_links
    get "/sitemap.xml"
    assert last_response.ok?
    assert_no_link "/government/some-content"
  end

  def test_should_include_content_from_all_indices

    result_links = ["/", "/an-example-answer", "/another-example-answer"]

    @index_names[1..-1].each do |index_name|
      link = "/#{index_name}/a-thing"
      document = {
        "title" => "Fetid Dingo's Kidneys",
        "description" => "Bugblatter Beast of Traal",
        "format" => "thing",
        "link" => link,
        "indexable_content" => "Always bring a towel."
      }
      post "/#{index_name}/documents", MultiJson.encode(document)
      result_links << link
      assert last_response.ok?
      post "/#{index_name}/commit", nil
      assert last_response.ok?
    end

    get "/sitemap.xml"
    assert last_response.headers["Content-Type"].include?("application/xml")
    assert last_response.ok?
    assert_result_links *result_links, order: false
  end
end
