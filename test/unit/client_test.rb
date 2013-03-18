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
    RestClient.expects(:get).raises(internal_server_error)
    Logging.logger[Elasticsearch::Client].expects(:error)
      .with(regexp_matches(/STUFF AND THINGS BROKE/))

    assert_raises RestClient::InternalServerError do
      Elasticsearch::Client.new("http://localhost/").get("")
    end
  end

  def test_changes_error_log_level
    # Test we can change the log level for the duration of a block

    RestClient.expects(:get).raises(internal_server_error)
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

    RestClient.expects(:get).raises(internal_server_error)
    RestClient.expects(:head).raises(internal_server_error("More breakage"))

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
end
