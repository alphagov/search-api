require "integration_test_helper"
require "rest-client"
require_relative "multi_index_test"

class SearchEntityBoostingTest < MultiIndexTest
  include Fixtures::EntityExtractorStubs

  def populate_content_indexes
    stub_entity_extractor("cheese sandwich", ["1"])
    insert_document(INDEX_NAMES.first, {
      "title" => "A",
      "link" => "/a",
      "indexable_content" => "cheese",
    })
    insert_document(INDEX_NAMES.first, {
      "title" => "B",
      "link" => "/b",
      "indexable_content" => "cheese sandwich",
    })
    commit_index(INDEX_NAMES.first)
    assert last_response.ok?, "Failed to insert document"
  end

  def insert_document(index_name, attributes)
    post "/#{index_name}/documents", MultiJson.encode(attributes)
    assert last_response.ok?, "Failed to insert document"
  end

  def assert_result_links_in_order(expected)
    links = parsed_response["results"].map do |result|
      result["link"]
    end

    assert_equal expected, links
  end

  def test_result_order_not_affected_if_no_named_entities_in_query
    get "/unified_search?q=cheese"
    assert_equal 200, last_response.status
    assert_result_links_in_order ["/a", "/b"]
  end

  def test_queries_with_named_entities_boost_documents_containing_those_entities
    stub_entity_extractor("cheese", ["1"])

    get "/unified_search?q=cheese"
    assert_equal 200, last_response.status
    assert_result_links_in_order ["/b", "/a"]
  end

end
