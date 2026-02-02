def logger
  Logging.logger.root
end

def search_server(cluster: Clusters.default_cluster)
  SearchConfig.instance(cluster).search_server
end

def clusters_from_args(args)
  return Clusters.active unless args[:clusters].present?

  derive_clusters(args[:clusters].split(" "))
end

def derive_clusters(cluster_keys = [])
  unpermitted_cluster = cluster_keys.find { |key| Clusters.cluster_keys.exclude?(key) }

  if unpermitted_cluster.present?
    raise("`clusters` must be one of #{Clusters.cluster_keys.join(', ')}. \n
          Leave this field blank to run against all clusters.")
  end

  Clusters.active.select { |cluster| cluster_keys.include? cluster.key }
end

def warn_for_single_cluster_run
  puts "WARNING: this will only run on the default cluster."
end

def index_names
  search_index = ENV["SEARCH_INDEX"]
  case search_index
  when "all"
    SearchConfig.all_index_names
  when String
    [search_index]
  else
    raise "You must specify an index name in SEARCH_INDEX, or 'all'"
  end
end

def max_index_age
  max_age_in_days = ENV["MAX_INDEX_AGE"]
  case max_age_in_days
  when String
    max_age_in_days
  else
    raise "You must specify the MAX_INDEX_AGE (e.g. MAX_INDEX_AGE=3)"
  end
end
