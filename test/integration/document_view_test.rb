require "integration_test_helper"

class DocumentViewtest < IntegrationTest

  def setup
    super
    disable_secondary_search
  end

  def test_should_view_existing_document
    @primary_search.expects(:get).returns(sample_document)

    get "/documents/%2Ffoobang"

    assert_equal 200, last_response.status
    assert last_response.content_type.start_with? "application/json"
    assert_equal sample_document.to_hash, JSON.parse(last_response.body)
  end

  def test_should_404_on_missing_document
    @primary_search.expects(:get).returns(nil)

    get "/documents/%2Ffoobang"

    assert_equal 404, last_response.status
  end
end
