require "integration_test_helper"
require "app"
require "rest-client"
require "nokogiri"

class SitemapTest < IntegrationTest

  def setup
    use_elasticsearch_for_primary_search
    app.any_instance.stubs(:secondary_search).returns(stub(search: []))
    WebMock.disable_net_connect!(allow: "localhost:9200")
    reset_elasticsearch_index
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
      }
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |sample_document|
      post "/documents", JSON.dump(sample_document)
      assert last_response.ok?
    end
  end

  def assert_result_links(*links)
    doc = Nokogiri::XML(last_response.body)
    paths = doc.css('loc').collect(&:text).map { |l| URI.parse(l).path }

    assert_equal links, paths
  end

  def test_should_return_a_sitemap
    get "/sitemap.xml"
    assert last_response.headers["Content-Type"].include?("application/xml")
    assert last_response.ok?
    assert_result_links "/", "/an-example-answer", "/another-example-answer"
  end
end
