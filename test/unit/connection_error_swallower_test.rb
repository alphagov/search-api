require "test_helper"
require "connection_error_swallower"
require 'logger'

class ConnectionErrorSwallowerTest < MiniTest::Unit::TestCase

  def setup
    @inner = stub("inner", call: nil)
    @logstream = StringIO.new
    @swallower = ConnectionErrorSwallower.new(@inner, logger: Logger.new(@logstream))
  end

  def test_swallows_first_connection_error_and_returns_nil
    @inner.stubs(:call).raises(Errno::ECONNREFUSED)
    assert_nil @swallower.call
  end

  def test_logs_first_connection_error
    @inner.stubs(:call).raises(Errno::ECONNREFUSED)
    @swallower.call
    assert_match /Connection refused/, @logstream.string
  end

  def test_silently_swallows_subsequent_errors
    @inner.stubs(:call).raises(Errno::ECONNREFUSED)
    @swallower.call
    assert_nil @swallower.call
    assert_nil @swallower.call

    matches = @logstream.string.scan(/Connection refused/)
    assert_equal 1, matches.size, "expected only 'Connection refused' match but got #{matches.size}"
  end

  def test_reraises_other_exceptions
    @inner.stubs(:call).raises("another error")
    assert_raises(RuntimeError) do
      @swallower.call
    end
  end
end
