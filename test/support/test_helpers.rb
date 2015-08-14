module TestHelpers
  include SampleConfig

  def teardown
    Timecop.return
  end

  # This can be used to partially match a hash in the context of an assert_equal
  # e.g. The following would pass
  #
  # assert_equal hash_including(one: 1), {one: 1, two: 2}
  #
  def hash_including(subset)
    HashIncludingMatcher.new(subset)
  end

  class HashIncludingMatcher
    def initialize(subset)
      @subset = subset
    end

    def ==(other)
      @subset.all? { |k,v|
        other.has_key?(k) && v == other[k]
      }
    end

    def inspect
      @subset.inspect
    end
  end

  def stub_elasticsearch_request(hash)
    hash.each do |url, response|
      stub_request(:get, "http://localhost:9200#{url}").to_return(body: JSON.dump(response))
    end
  end

  def search_query_params(options={})
    SearchParameters.new({
      start: 0,
      count: 20,
      query: "cheese",
      order: nil,
      filters: {},
      return_fields: nil,
      facets: nil,
      debug: {},
    }.merge(options))
  end
end
