class Cache
  COMBINED_INDEX_SCHEMA = "COMBINED_INDEX_SCHEMA:".freeze
  SEARCH_SERVERS = "SEARCH_SERVERS:".freeze
  SEARCH_CONFIG = "SEARCH_CONFIG:".freeze
  CLUSTER = "CLUSTER:".freeze
  ACTIVE_CLUSTERS = "ACTIVE_CLUSTERS:".freeze
  STATSD_CLIENT = "STATSD_CLIENT:".freeze

  @cache = {}

  def self.get(key)
    if @cache.key?(key)
      @cache[key]
    else
      block_given? ? (@cache[key] = yield) : nil
    end
  end

  def self.clear
    @cache = {}
  end
end
