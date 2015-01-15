require "test_helper"
require "entity_extractor_client"

class EntityExtractorClientTest < MiniTest::Unit::TestCase
  def test_extract_calls_entity_extractor_service_and_deserialises_json_response
    document = "This is my document"
    post_stub = stub_request(:post, "http://localhost:3096/extract")
      .with(body: document)
      .to_return(
        status: 200,
        body: '["1"]'
      )
    e = EntityExtractorClient.new("http://localhost:3096/")
    response = e.call(document)

    assert_equal ["1"], response
  end
end
