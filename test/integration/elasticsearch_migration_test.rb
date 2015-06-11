require "integration_test_helper"
require "rack/logger"
require "bulk_loader"

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
    add_documents(sample_document_attributes)
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

  def add_documents(documents)
    documents.each do |document|
      post "/documents", document.to_json
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

    get "/unified_search?q=directive"
    assert_equal 2, JSON.parse(last_response.body)["results"].length

    @stemmer["rules"] = ["directive => directive"]

    index_group = search_server.index_group("mainstream_test")
    original_index_name = index_group.current_real.real_name

    BulkLoader.new(search_config, "mainstream_test").load_from_current_index

    # Ensure the indexes have actually been switched.
    refute_equal original_index_name, index_group.current_real.real_name

    get "/unified_search?q=directive"
    assert_result_links "/important"

    get "/unified_search?q=direct"
    assert_result_links "/aliens"
  end

  def test_full_reindex_multiple_batches
    test_batch_size = 30
    index_group = search_server.index_group("mainstream_test")
    extra_documents = (test_batch_size + 5).times.map do |n|
      {
        "_type" => "edition",
        "title" => "Document #{n}",
        "format" => "answer",
        "link" => "/doc-#{n}",
      }
    end
    index_group.current_real.bulk_index(extra_documents)
    commit_index

    get "/unified_search?q=directive"
    assert_equal 2, JSON.parse(last_response.body)["results"].length

    @stemmer["rules"] = ["directive => directive"]

    index_group = search_server.index_group("mainstream_test")
    original_index_name = index_group.current_real.real_name

    BulkLoader.new(search_config, "mainstream_test", :document_batch_size => test_batch_size).load_from_current_index

    # Ensure the indexes have actually been switched.
    refute_equal original_index_name, index_group.current_real.real_name

    get "/unified_search?q=directive"
    assert_result_links "/important"

    get "/unified_search?q=direct"
    assert_result_links "/aliens"

    get "/unified_search?q=Document&count=100"
    assert_equal test_batch_size + 5, JSON.parse(last_response.body)["results"].length
  end

  def test_handles_errors_correctly
    # Test that an error while re-indexing is reported, and aborts the whole process.

    Elasticsearch::Index.any_instance.stubs(:bulk_index).raises(Elasticsearch::IndexLocked)

    get "/unified_search?q=directive"
    assert_equal 2, JSON.parse(last_response.body)["results"].length

    @stemmer["rules"] = ["directive => directive"]

    index_group = search_server.index_group("mainstream_test")
    original_index_name = index_group.current_real.real_name

    assert_raises Elasticsearch::IndexLocked do
      BulkLoader.new(search_config, "mainstream_test").load_from_current_index
    end

    # Ensure the the indexes haven't been swapped
    assert_equal original_index_name, index_group.current_real.real_name

    get "/unified_search?q=directive"
    assert_equal 2, JSON.parse(last_response.body)["results"].length
  end

  def test_reindex_with_no_existing_index
    # Test that a reindex will still create the index and alias with no
    # existing index

    try_remove_test_index

    BulkLoader.new(search_config, "mainstream_test").load_from_current_index

    index_group = search_server.index_group("mainstream_test")
    new_index = index_group.current_real
    refute_nil new_index

    # Ensure it's an aliased index
    refute_equal "mainstream_test", new_index.real_name
  end
end
