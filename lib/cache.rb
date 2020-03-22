class Cache
  COMBINED_INDEX_SCHEMA = "COMBINED_INDEX_SCHEMA:".freeze
  SEARCH_SERVERS = "SEARCH_SERVERS:".freeze
  SEARCH_CONFIG = "SEARCH_CONFIG:".freeze
  CLUSTER = "CLUSTER:".freeze
  ACTIVE_CLUSTERS = "ACTIVE_CLUSTERS:".freeze
  STATSD_CLIENT = "STATSD_CLIENT:".freeze

  @cache = {}

  @redis_cache = Redis.new(
    host: ENV.fetch("REDIS_HOST", "127.0.0.1"),
    port: ENV.fetch("REDIS_PORT", 6379),
    namespace: "search-api-cache",
  )

  def self.get(key)
    if @cache.has_key?(key)
      @cache[key]
    else
      block_given? ? (@cache[key] = yield) : nil
    end
  end

  def self.getex(key, expiration: 30)
    value = @redis_cache.get(key)
    if value.nil? && block_given?
      value = yield
      @redis_cache.setex(key, expiration, value)
    end
    value
  end

  def self.clear
    @cache = {}
    @redis_cache.flushall
  end
end
