require "integration_test_helper"
require "rest-client"
require "bulk_loader"
require "cgi"

class BulkLoaderTest < IntegrationTest

  def setup
    stub_elasticsearch_settings
    clean_test_indexes

    @sample_document = {
      "title" => "TITLE",
      "description" => "DESCRIPTION",
      "format" => "answer",
      "link" => "/an-example-answer",
      "indexable_content" => "HERE IS SOME CONTENT"
    }
    create_test_indexes
  end

  def teardown
    clean_test_indexes
  end

  def retrieve_document_from_rummager(link)
    get "/documents/#{CGI::escape(link)}"
    parsed_response
  end

  def assert_document_is_in_rummager(document, skip_keys=["popularity"])
    retrieved = retrieve_document_from_rummager(document['link'])
    retrieved_document_keys = retrieved.keys - skip_keys

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

    [
      index_action.to_json,
      document.to_json
    ].join("\n") + "\n"
  end

  def test_indexes_documents
    bulk_loader = BulkLoader.new(app.settings.search_config, DEFAULT_INDEX_NAME)
    bulk_loader.load_from(StringIO.new(index_payload(@sample_document)))

    assert_document_is_in_rummager(@sample_document)
  end

  def test_updates_an_existing_document
    insert_stub_popularity_data(@sample_document["link"])

    index_group = search_server.index_group(DEFAULT_INDEX_NAME)
    old_index = index_group.current_real

    doc_v1 = @sample_document.merge({"title" => "Original Title"})
    doc_v2 = @sample_document.merge({"title" => "New Title"})

    post "/documents", doc_v1.to_json
    old_index.commit
    assert_document_is_in_rummager(doc_v1)

    bulk_loader = BulkLoader.new(app.settings.search_config, DEFAULT_INDEX_NAME)
    bulk_loader.load_from(StringIO.new(index_payload(doc_v2)))

    assert_document_is_in_rummager(doc_v2)
  end

  def test_adds_extra_fields
    # We have to insert at least two popularity documents to get a popularity
    # score other than the maximum, because the popularity is based on the rank of the
    # document when ordered by traffic, and the rank is capped at the number of
    # documents in the popularity index.  The actual value we insert here is a
    # rank of 10, but because there are two documents the popularity value we
    # get returned is 1/(2 + popularity_rank_offset), where
    # popularity_rank_offset is a configuration value which is set to 10 by
    # default.
    insert_stub_popularity_data(@sample_document["link"])
    insert_stub_popularity_data("/another-example")

    bulk_loader = BulkLoader.new(app.settings.search_config, DEFAULT_INDEX_NAME)
    bulk_loader.load_from(StringIO.new(index_payload(@sample_document)))

    assert_document_is_in_rummager(
      @sample_document.merge("popularity" => 1.0/12), []
    )
  end
end
