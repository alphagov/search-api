require "test_helper"
require "timed_cache"

class TimedCacheTest < MiniTest::Unit::TestCase
  def test_result_is_not_called_until_needed
    fetch = stub("fetch")
    fetch.expects(:call).never

    TimedCache.new(5) { fetch.call }
  end

  def test_result_is_cached
    fetch = stub("fetch")
    fetch.expects(:call).returns("foo").once

    cache = TimedCache.new(5) { fetch.call }
    2.times { assert_equal "foo", cache.get }
  end

  def test_cache_does_not_expire_within_lifetime
    time_state = states("time").starts_as("now")
    clock = stub("clock") do
      # Using explicit timestamps to make sure the lifespan is in seconds
      initial_time = Time.new(2013, 1, 1, 12, 0, 0)
      stubs(:now).when(time_state.is("now")).returns(initial_time)
      later_time = Time.new(2013, 1, 1, 12, 0, 4)
      stubs(:now).when(time_state.is("before expiry")).returns(later_time)
    end
    fetch = stub("fetch") do
      expects(:call).returns("foo").once
    end

    cache = TimedCache.new(5, clock) { fetch.call }
    cache.get
    time_state.become("before expiry")
    cache.get
  end

  def test_cache_expires
    time_state = states("time").starts_as("now")
    clock = stub("clock") do
      # Using explicit timestamps to make sure the lifespan is in seconds
      initial_time = Time.new(2013, 1, 1, 12, 0, 0)
      stubs(:now).when(time_state.is("now")).returns(initial_time)
      later_time = Time.new(2013, 1, 1, 12, 0, 6)
      stubs(:now).when(time_state.is("after expiry")).returns(later_time)
    end
    fetch = stub("fetch") do
      expects(:call).returns("foo").twice
    end

    cache = TimedCache.new(5, clock) { fetch.call }
    assert_equal "foo", cache.get
    time_state.become("after expiry")
    assert_equal "foo", cache.get
  end
end
