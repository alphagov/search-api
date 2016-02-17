require "integration_test_helper"

class ContentEndpointsTest < IntegrationTest
  def setup
    stub_elasticsearch_settings
    create_test_indexes
  end

  def teardown
    clean_test_indexes
  end

  def test_content_document_not_found
    get "/content?link=/a-document/that-does-not-exist"

    assert last_response.not_found?
  end

  def test_that_getting_a_document_returns_the_document
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    get "/content?link=a-document/in-search"

    assert last_response.ok?
    assert_equal(
      { "title" => "A nice title", "link" => "a-document/in-search" },
      parsed_response['raw_source']
    )
  end

  def test_deleting_a_document
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    delete "/content?link=a-document/in-search"

    assert_equal 204, last_response.status
  end

  def test_deleting_a_document_that_doesnt_exist
    delete "/content?link=a-document/in-search"

    assert last_response.not_found?
  end

  def test_deleting_a_document_from_locked_index
    commit_document("mainstream_test", {
      "title" => "A nice title",
      "link" => "a-document/in-search",
    })

    Elasticsearch::Index.any_instance.expects(:delete).raises(Elasticsearch::IndexLocked)

    delete "/content?link=a-document/in-search"

    assert_equal 423, last_response.status
  end
end
