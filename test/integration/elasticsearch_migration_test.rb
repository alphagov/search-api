require "integration_test_helper"
require "rack/logger"

class ElasticsearchMigrationTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    try_remove_test_index

    schema = app.settings.search_config.schema_config
    settings = schema.elasticsearch_settings("mainstream_test")
    schema.stubs(:elasticsearch_settings).returns(settings)
    @stemmer = settings["analysis"]["filter"]["stemmer_override"]
    @stemmer["rules"] = ["fish => fish"]

    create_test_indexes
    add_sample_documents
    commit_index
  end

  def teardown
    clean_test_indexes
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
      post "/documents", sample_document.to_json
      assert last_response.ok?
    end
  end

  def commit_index
    post "/commit", nil
  end

  def assert_result_links(*links)
    parsed_response = JSON.parse(last_response.body)
    assert_equal links, parsed_response["results"].map { |r| r["link"] }
  end

  def test_full_reindex
    # Test that a reindex re-adds all the documents with new
    # stemming settings

    get "/search?q=directive"
    assert_equal 2, JSON.parse(last_response.body)["results"].length

    @stemmer["rules"] = ["directive => directive"]

    index_group = search_server.index_group("mainstream_test")
    new_index = index_group.create_index
    new_index.populate_from index_group.current

    index_group.switch_to new_index

    get "/search?q=directive"
    assert_result_links "/important"

    get "/search?q=direct"
    assert_result_links "/aliens"
  end
end
