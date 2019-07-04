class Cache
  COMBINED_INDEX_SCHEMA = 'COMBINED_INDEX_SCHEMA:'
  SEARCH_SERVERS = 'SEARCH_SERVERS:'
  SEARCH_CONFIG = 'SEARCH_CONFIG:'
  CLUSTER = 'CLUSTER:'
  ACTIVE_CLUSTERS = 'ACTIVE_CLUSTERS:'

  @@cache = {}

  def self.get(key)
    @@cache[key] || begin
       block_given? ? (@@cache[key] = yield) : nil
    end
  end

  def self.put(key, value)
    @@cache[key] = value
  end

  def self.clear
    @@cache = {}
  end
end