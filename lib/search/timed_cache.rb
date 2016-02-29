module Search
  class TimedCache
    # Evaluate a block, caching the result for a given number of seconds.
    #
    # Example:
    #
    #   cache = TimedCache.new(30) { "Something" + " really difficult" }
    #   cache.get

    def initialize(lifetime, clock = Time, &block)
      @cached_result = nil
      @cache_updated = nil
      @lifetime = lifetime
      @clock = clock
      @block = block
    end

    def get
      if refresh_needed?
        @cached_result = @block.call
        @cache_updated = @clock.now
      end
      @cached_result
    end

  private

    def refresh_needed?
      @cached_result.nil? || @cache_updated.nil? || cache_age >= @lifetime
    end

    def cache_age
      @clock.now - @cache_updated
    end
  end
end
