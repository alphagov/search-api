PROJECT_ROOT = File.dirname(__FILE__)
LIBRARY_PATH = File.join(PROJECT_ROOT, "lib")

[PROJECT_ROOT, LIBRARY_PATH].each do |path|
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

require "rummager"
require "rummager/config"

Dir[File.join(PROJECT_ROOT, "lib/tasks/**/*.rake")].each { |file| load file }

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task default: [:spec, :lint]

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
