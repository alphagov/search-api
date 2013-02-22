require "integration_test_helper"

class DocumentViewtest < IntegrationTest

  def setup
    super
    stub_backend
  end

  def test_should_view_existing_document
    @backend_index.expects(:get).returns(sample_document)

    get "/documents/%2Ffoobang"

    assert_equal 200, last_response.status
    assert last_response.content_type.start_with? "application/json"
    assert_equal sample_document.to_hash, MultiJson.decode(last_response.body)
  end

  def test_should_404_on_missing_document
    @backend_index.expects(:get).returns(nil)

    get "/documents/%2Ffoobang"

    assert_equal 404, last_response.status
  end
end
