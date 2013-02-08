require "integration_test_helper"
require "app"
require "rest-client"
require "nokogiri"

class SitemapTest < IntegrationTest

  def setup
    stub_backends_with(
      {
        primary: {
          type: "elasticsearch",
          server: "localhost",
          port: 9200,
          index_name: "mainstream_test"
        },
        mainstream: {
          type: "elasticsearch",
          server: "localhost",
          port: 9200,
          index_name: "mainstream_test"
        },
        detailed: {
          type: "elasticsearch",
          server: "localhost",
          port: 9200,
          index_name: "detailed_test"
        },
        government: {
          type: "elasticsearch",
          server: "localhost",
          port: 9200,
          index_name: "government_test"
        }
      }
    )

    WebMock.disable_net_connect!(allow: "localhost:9200")
    reset_elasticsearch_index(:mainstream)
    reset_elasticsearch_index(:detailed)
    reset_elasticsearch_index(:government)
    add_sample_documents
    commit_index
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
    doc = Nokogiri::XML(last_response.body)
    paths = doc.css('loc').collect(&:text).map { |l| URI.parse(l).path }

    assert_equal links, paths
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
    assert_result_links "/", "/an-example-answer", "/another-example-answer"
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

  def test_should_include_content_from_mainstream_and_detailed_indexes
    document_in_another_index = {
      "title" => "Fetid Dingo's Kidneys",
      "description" => "Bugblatter Beast of Traal",
      "format" => "specialist",
      "link" => "/a-specialist-guidance",
      "indexable_content" => "Always bring a towel."
    }
    post "/detailed/documents", MultiJson.encode(document_in_another_index)
    assert last_response.ok?
    post "/detailed/commit", nil
    assert last_response.ok?

    get "/sitemap.xml"
    assert last_response.headers["Content-Type"].include?("application/xml")
    assert last_response.ok?
    assert_result_links "/", "/an-example-answer", "/another-example-answer", "/a-specialist-guidance"
  end
end
