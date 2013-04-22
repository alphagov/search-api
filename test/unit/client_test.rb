require "test_helper"
require "elasticsearch/client"
require "rest-client"
require "logging"

class ClientTest < MiniTest::Unit::TestCase

  def internal_server_error(body = "STUFF AND THINGS BROKE")
    RestClient::InternalServerError.new(
      # Can't use stub() here, because RestClient does weird inspection
      Struct.new(:code, :body).new("500", body)
    )
  end

  def test_logs_error_body
    RestClient::Request.expects(:execute).with(has_entry(method: :get))
      .raises(internal_server_error)

    Logging.logger[Elasticsearch::Client].expects(:error)
      .with(regexp_matches(/STUFF AND THINGS BROKE/))

    assert_raises RestClient::InternalServerError do
      Elasticsearch::Client.new("http://localhost/").get("")
    end
  end

  def test_changes_error_log_level
    # Test we can change the log level for the duration of a block

    RestClient::Request.expects(:execute).with(has_entry(method: :get))
      .raises(internal_server_error)

    Logging.logger[Elasticsearch::Client].expects(:warn)
      .with(regexp_matches(/STUFF AND THINGS BROKE/))

    client = Elasticsearch::Client.new("http://localhost/")
    assert_raises RestClient::InternalServerError do
      client.with_error_log_level(:warn) do
        client.get("")
      end
    end
  end

  def test_resets_error_log_level
    # Test that the error log level goes back to normal outside the block

    RestClient::Request.expects(:execute).with(has_entry(method: :get))
      .raises(internal_server_error)
    RestClient::Request.expects(:execute).with(has_entry(method: :head))
      .raises(internal_server_error("More breakage"))

    Logging.logger[Elasticsearch::Client].expects(:warn)
      .with(regexp_matches(/STUFF AND THINGS BROKE/))
    Logging.logger[Elasticsearch::Client].expects(:error)
      .with(regexp_matches(/More breakage/))

    client = Elasticsearch::Client.new("http://localhost/")
    assert_raises RestClient::InternalServerError do
      client.with_error_log_level(:warn) do
        client.get("")
      end
    end
    assert_raises RestClient::InternalServerError do
      client.head("")
    end
  end

  def test_timeout
    # Test that Elasticsearch::Client accepts a timeout option and passes it on
    # to RestClient
    RestClient::Request.expects(:execute).with(has_entries(timeout: 10))
    Elasticsearch::Client.new("http://localhost/", timeout: 10).get("")
  end

  def test_open_timeout
    # Test that Elasticsearch::Client accepts an open_timeout option and passes
    # it on to RestClient
    RestClient::Request.expects(:execute).with(has_entries(open_timeout: 10))
    Elasticsearch::Client.new("http://localhost/", open_timeout: 10).get("")
  end
end
