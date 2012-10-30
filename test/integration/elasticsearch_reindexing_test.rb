require "integration_test_helper"
require "app"
require "rest-client"
require "reindexer"
require "rack/logger"

class ElasticsearchReindexingTest < IntegrationTest

  def setup
    use_elasticsearch_for_primary_search
    app.any_instance.stubs(:secondary_search).returns(stub(search: []))
    WebMock.disable_net_connect!(allow: "localhost:9200")

    es_settings = settings.elasticsearch_schema["index"]["settings"]
    @stemmer = es_settings["analysis"]["filter"]["stemmer_override"]
    # Save for restore on teardown
    @original_rules = @stemmer["rules"]
    @stemmer["rules"] = ["fish => fish"]  # elasticsearch needs at least 1 rule

    reset_elasticsearch_index
    add_sample_documents
    commit_index
  end

  def teardown
    @stemmer["rules"] = @original_rules
  end

  def sample_document_attributes
    [
      {
        "title" => "Important government directive",
        "format" => "answer",
        "link" => "/important",
      },
      {
        "title" => "Direct contact with aliens",
        "format" => "answer",
        "link" => "/aliens",
      }
    ]
  end

  def add_sample_documents
    sample_document_attributes.each do |sample_document|
      post "/documents", JSON.dump(sample_document)
      assert last_response.ok?
    end
  end

  def commit_index
    post "/commit", nil
  end

  def assert_result_links(*links)
    parsed_response = JSON.parse(last_response.body)
    assert_equal links, parsed_response.map { |r| r["link"] }
  end

  def test_full_reindex
    # Test that a reindex re-adds all the documents with new
    # stemming settings

    get "/search?q=directive"
    assert_equal 2, JSON.parse(last_response.body).length

    @stemmer["rules"] = ["directive => directive"]
    update_elasticsearch_index

    backends = Backends.new(settings)
    Reindexer.new(backends[:primary]).reindex_all

    get "/search?q=directive"
    assert_result_links "/important"

    get "/search?q=direct"
    assert_result_links "/aliens"
  end
end
