require "integration_test_helper"
require "rack/logger"

class ElasticsearchMigrationTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    try_remove_test_index

    stub_modified_schema do |schema|
      @stemmer = schema["index"]["settings"]["analysis"]["filter"]["stemmer_override"]
      @stemmer["rules"] = ["fish => fish"]
    end

    create_test_index
    add_sample_documents
    commit_index
  end

  def teardown
    clean_index_group
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
      post "/documents", MultiJson.encode(sample_document)
      assert last_response.ok?
    end
  end

  def commit_index
    post "/commit", nil
  end

  def assert_result_links(*links)
    parsed_response = MultiJson.decode(last_response.body)
    assert_equal links, parsed_response.map { |r| r["link"] }
  end

  def test_full_reindex
    # Test that a reindex re-adds all the documents with new
    # stemming settings

    get "/search?q=directive"
    assert_equal 2, MultiJson.decode(last_response.body).length

    @stemmer["rules"] = ["directive => directive"]

    index_group = search_server.index_group("rummager_test")
    new_index = index_group.create_index
    new_index.populate_from index_group.current

    index_group.switch_to new_index

    get "/search?q=directive"
    assert_result_links "/important"

    get "/search?q=direct"
    assert_result_links "/aliens"
  end
end
