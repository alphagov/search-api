require "spec_helper"

RSpec.describe Search::TimedCache do
  it "result is not called until needed" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).never

    described_class.new(5) { fetch.call }
  end

  it "result is cached" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).and_return("foo").once

    cache = described_class.new(5) { fetch.call }
    2.times { expect(cache.get).to eq("foo") }
  end

  it "cache does not expire within lifetime" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).and_return("foo").once

    clock = double
    initial_time = Time.new(2013, 1, 1, 12, 0, 0)
    later_time = Time.new(2013, 1, 1, 12, 0, 4)

    cache_lifetime = 5
    cache = described_class.new(cache_lifetime, clock) { fetch.call }

    allow(clock).to receive(:now).and_return(initial_time)
    cache.get

    allow(clock).to receive(:now).and_return(later_time)
    cache.get
  end

  it "cache expires" do
    fetch = double("fetch")
    expect(fetch).to receive(:call).and_return("foo").twice

    clock = double
    initial_time = Time.new(2013, 1, 1, 12, 0, 0)
    later_time = Time.new(2013, 1, 1, 12, 0, 6)

    cache_lifetime = 5
    cache = described_class.new(cache_lifetime, clock) { fetch.call }

    allow(clock).to receive(:now).and_return(initial_time)
    cache.get

    allow(clock).to receive(:now).and_return(later_time)
    cache.get
  end
end
