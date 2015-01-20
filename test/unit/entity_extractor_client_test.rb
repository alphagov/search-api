require "test_helper"
require "entity_extractor_client"
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

  def test_logs_and_swallows_first_connection_error_if_swallowing_connection_errors
    @extractor = EntityExtractorClient.new(@base_url,
      logger: Logger.new(@logstream),
      swallow_connection_errors: true
    )
    stub_request(:post, "#{@base_url}/extract")
      .with(body: "some text")
      .to_raise(Errno::ECONNREFUSED)
    assert_nil @extractor.call("some text")
    assert_match /Connection refused/, @logstream.string
  end

  def test_silently_swallows_subsequent_connection_errors_if_swallowing_connection_errors
    @extractor = EntityExtractorClient.new(@base_url,
      logger: Logger.new(@logstream),
      swallow_connection_errors: true
    )
    stub_request(:post, "#{@base_url}/extract")
      .with(body: "some text")
      .to_raise(Errno::ECONNREFUSED)

    assert_nil @extractor.call("some text")
    assert_nil @extractor.call("some text")
    assert_nil @extractor.call("some text")
    matches = @logstream.string.scan(/Connection refused/)
    assert_equal 1, matches.size, "expected only 'Connection refused' match but got #{matches.size}"
  end

  def test_raises_connection_error_if_not_swallowing
    @extractor = EntityExtractorClient.new(@base_url,
      logger: Logger.new(@logstream),
      swallow_connection_errors: false
    )
    stub_request(:post, "#{@base_url}/extract")
      .with(body: "some text")
      .to_raise(Errno::ECONNREFUSED)

    assert_raises(Errno::ECONNREFUSED) do
      @extractor.call("some text")
    end
  end

  def test_raises_timeouts_even_if_swallowing
    @extractor = EntityExtractorClient.new(@base_url,
      logger: Logger.new(@logstream),
      swallow_connection_errors: true
    )
    stub_request(:post, "#{@base_url}/extract")
      .with(body: "some text")
      .to_timeout

    assert_raises(RestClient::RequestTimeout) do
      @extractor.call("some text")
    end
  end
end
