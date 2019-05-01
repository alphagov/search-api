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

task default: [:spec, :lint]

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
  search_index = ENV["SEARCH_INDEX"]
  case search_index
  when "all"
    search_config.all_index_names
  when String
    [search_index]
  else
    raise "You must specify an index name in SEARCH_INDEX, or 'all'"
  end
end
