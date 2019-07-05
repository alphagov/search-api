class Cache
  COMBINED_INDEX_SCHEMA = 'COMBINED_INDEX_SCHEMA:'
  SEARCH_SERVERS = 'SEARCH_SERVERS:'
  SEARCH_CONFIG = 'SEARCH_CONFIG:'
  CLUSTER = 'CLUSTER:'
  ACTIVE_CLUSTERS = 'ACTIVE_CLUSTERS:'

  @@cache = {}

  def self.get(key)
    if @@cache.has_key?(key)
      @@cache[key]
    else
      block_given? ? (@@cache[key] = yield) : nil
    end
  end

  def self.clear
    @@cache = {}
  end
end