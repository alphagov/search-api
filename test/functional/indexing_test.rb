require "integration_test_helper"

class IndexingTest < IntegrationTest

  def document_hashes
    [
      {
        "link" => "/foo",
        "title" => "Foo"
      }
    ]
  end

  def test_can_submit_documents
    # The default is false, but let's be explicit about it
    app.settings.expects(:enable_queue).returns(false)
    index = stub_index

    index.expects(:document_from_hash).with(document_hashes[0]).returns(:foo)
    index.expects(:add).with([:foo]).returns(true)

    post "/documents", MultiJson.encode(document_hashes), :content_type => :json

    assert_equal 200, last_response.status
  end

  def test_can_submit_documents_asynchronously
    app.settings.expects(:enable_queue).returns(true)
    index = stub_index
    index.expects(:document_from_hash).with(document_hashes[0]).returns(:foo)
    index.expects(:add_queued).with([:foo]).returns(true)

    post "/documents", MultiJson.encode(document_hashes), :content_type => :json

    assert_equal 202, last_response.status
  end
end
