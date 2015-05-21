require "integration_test_helper"
require "rest-client"
require_relative "multi_index_test"

class CombinedSearchTest < MultiIndexTest
  def setup
    stub_elasticsearch_configuration
  end

  def test_returns_success
    create_meta_indexes
    reset_content_indexes

    get "/govuk/search?q=important"

    assert last_response.ok?
  end

  def test_returns_streams
    create_meta_indexes
    reset_content_indexes

    get "/govuk/search?q=important"

    expected_streams = [
      "top-results",
      "services-information",
      "departments-policy"
    ].to_set
    assert_equal expected_streams, parsed_response["streams"].keys.to_set
  end

  def test_blocks_requests_in_formats_other_than_json
    get "/govuk/search.xml?q=important"
    assert_equal 404, last_response.status

    get "/some_index/search.haml?q=important"
    assert_equal 404, last_response.status

    get "/some_index/advanced_search.soap?page=1&per_page=1&q=important"
    assert_equal 404, last_response.status

    get "/organisations.fishslice"
    assert_equal 404, last_response.status
  end

  def test_returns_3_top_results
    reset_content_indexes_with_content(section_count: 1)

    get "/govuk/search?q=important"

    assert_equal 3, parsed_response["streams"]["top-results"]["results"].count
  end
end
