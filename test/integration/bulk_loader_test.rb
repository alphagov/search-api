require "integration_test_helper"
require "rest-client"
require "bulk_loader"
require "cgi"

class BulkLoaderTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    enable_test_index_connections
    try_remove_test_index
    @sample_document = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }
  end

  def teardown
    clean_index_group
  end

  def retrieve_document_from_rummager(link)
    get "/documents/#{CGI::escape(link)}"
    MultiJson.decode(last_response.body)
  end

  def assert_document_is_in_rummager(document)
    retrieved = retrieve_document_from_rummager(document['link'])
    retrieved_document_keys = retrieved.keys - ["popularity"]

    assert_equal document.keys.sort, retrieved_document_keys.sort

    document.each do |key, value|
      assert_equal value, retrieved[key], "Field #{key} should be '#{value}' but was '#{retrieved[key]}'"
    end
  end

  def index_payload(document)
    index_action = {
      "index" => {
        "_id" => document['link'],
        "_type" => "edition"
      }
    }

    payload = [
      index_action.to_json,
      document.to_json
    ].join("\n") + "\n"
  end

  def test_indexes_documents
    create_test_indexes

    bulk_loader = BulkLoader.new(app.settings.search_config, @default_index_name)
    bulk_loader.load_from(StringIO.new(index_payload(@sample_document)))

    assert_document_is_in_rummager(@sample_document)
  end

  def test_updates_an_existing_document
    create_test_indexes
    insert_stub_popularity_data(@sample_document["link"])

    index_group = search_server.index_group(@default_index_name)
    old_index = index_group.current_real

    doc_v1 = @sample_document.merge({"title" => "Original Title"})
    doc_v2 = @sample_document.merge({"title" => "New Title"})

    post "/documents", MultiJson.encode(doc_v1)
    old_index.commit
    assert_document_is_in_rummager(doc_v1)

    bulk_loader = BulkLoader.new(app.settings.search_config, @default_index_name)
    bulk_loader.load_from(StringIO.new(index_payload(doc_v2)))

    assert_document_is_in_rummager(doc_v2)
  end
end
