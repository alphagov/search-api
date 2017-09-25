require 'spec_helper'

RSpec.describe 'TimedCacheTest' do
  it "result_is_not_called_until_needed" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).never

    Search::TimedCache.new(5) { fetch.call }
  end

  it "result_is_cached" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).and_return("foo").once

    cache = Search::TimedCache.new(5) { fetch.call }
    2.times { assert_equal "foo", cache.get }
  end

  it "cache_does_not_expire_within_lifetime" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).and_return("foo").once

    clock = double
    initial_time = Time.new(2013, 1, 1, 12, 0, 0)
    later_time = Time.new(2013, 1, 1, 12, 0, 4)

    cache_lifetime = 5
    cache = Search::TimedCache.new(cache_lifetime, clock) { fetch.call }

    allow(clock).to receive(:now).and_return(initial_time)
    cache.get

    allow(clock).to receive(:now).and_return(later_time)
    cache.get
  end

  it "cache_expires" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).and_return("foo").twice

    clock = double
    initial_time = Time.new(2013, 1, 1, 12, 0, 0)
    later_time = Time.new(2013, 1, 1, 12, 0, 6)

    cache_lifetime = 5
    cache = Search::TimedCache.new(cache_lifetime, clock) { fetch.call }

    allow(clock).to receive(:now).and_return(initial_time)
    cache.get

    allow(clock).to receive(:now).and_return(later_time)
    cache.get
  end
end
