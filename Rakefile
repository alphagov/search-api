PROJECT_ROOT = File.dirname(__FILE__)
LIBRARY_PATH = File.join(PROJECT_ROOT, "lib")

[PROJECT_ROOT, LIBRARY_PATH].each do |path|
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

require 'rummager'
require "rummager/config"

Dir[File.join(PROJECT_ROOT, 'lib/tasks/**/*.rake')].each { |file| load file }

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task default: :spec

def logger
  Logging.logger.root
end

def search_config
  SearchConfig.instance
end

def search_server
  search_config.search_server
end

def elasticsearch_uri
  SearchConfig.new.elasticsearch["base_uri"]
end

def index_names
  case ENV["RUMMAGER_INDEX"]
  when "all"
    search_config.all_index_names
  when String
    [ENV["RUMMAGER_INDEX"]]
  else
    raise "You must specify an index name in RUMMAGER_INDEX, or 'all'"
  end
end
