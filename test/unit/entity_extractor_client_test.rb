require "test_helper"
require "entity_extractor_client"
require "connection_error_swallower"
require 'logger'

class EntityExtractorClientTest < MiniTest::Unit::TestCase
  def setup
    @base_url = "http://localhost:3096"
    @logstream = StringIO.new
    @extractor = EntityExtractorClient.new(@base_url, logger: Logger.new(@logstream))
  end

  def test_extract_calls_entity_extractor_service_and_deserialises_json_response
    document = "This is my document"
    stub_request(:post, "#{@base_url}/extract")
      .with(body: document)
      .to_return(
        status: 200,
        body: '["1"]'
      )
    response = @extractor.call(document)

    assert_equal ["1"], response
  end
end
