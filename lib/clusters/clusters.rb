# The Clusters module is responsible for providing information about
# the various elasticsearch clusters that search-api can talk to.
module Clusters
  def self.count
    active.count
  end

  def self.default_cluster
    active.find(&:default)
  end

  def self.validate_cluster_key!(cluster_key)
    get_cluster(cluster_key)
    true
  rescue ClusterNotFoundError
    raise InvalidClusterError, "#{cluster_key} is not a valid cluster key!"
  end

  def self.cluster_keys
    active.map(&:key)
  end

  class InvalidClusterError < StandardError; end
  class ClusterNotFoundError < StandardError; end

  def self.get_cluster(cluster_key)
    found = active.find { |cluster| cluster.key == cluster_key }

    raise ClusterNotFoundError unless found

    found
  end

  def self.active
    Cache.get(Cache::ACTIVE_CLUSTERS) do
      defined_clusters = ElasticsearchConfig.new.config['clusters']
      defined_clusters.map { |cluster| Cluster.new(cluster.deep_symbolize_keys) }
      .reject(&:inactive?)
    end
  end
end
