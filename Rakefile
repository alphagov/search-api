require "rake/testtask"

PROJECT_ROOT = File.dirname(__FILE__)
LIBRARY_PATH = File.join(PROJECT_ROOT, "lib")

[PROJECT_ROOT, LIBRARY_PATH].each do |path|
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

require 'rummager'
require "rummager/config"

Dir[File.join(PROJECT_ROOT, 'lib/tasks/**/*.rake')].each { |file| load file }

desc "Run all the tests"
task "test" => [
  "test:units",
  "test:integration",
  'test:clean_test_indexes'
]

namespace "test" do
  desc "Run the unit tests"
  Rake::TestTask.new("units") do |t|
    t.libs << "test"
    t.test_files = FileList["test/unit/**/*_test.rb"]
    t.verbose = true
  end

  desc "Run the integration tests"
  Rake::TestTask.new("integration") do |t|
    t.libs << "test"
    t.test_files = FileList["test/integration/**/*_test.rb"]
    t.verbose = true
  end

  desc 'Clean all test indexes'
  task :clean_test_indexes do
    # Silence log output
    Logging.logger.root.appenders = nil

    require 'test/support/test_index_helpers'

    TestIndexHelpers.clean_all
  end
end

require "ci/reporter/rake/minitest" if ENV["RACK_ENV"] == "test"

task default: :test

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
