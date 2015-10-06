module HashIncludingHelpers
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
end
