require "rake/testtask"
require "logging"
require "pry-byebug"

PROJECT_ROOT = File.dirname(__FILE__)
LIBRARY_PATH = File.join(PROJECT_ROOT, "lib")

[PROJECT_ROOT, LIBRARY_PATH].each do |path|
  $LOAD_PATH.unshift(path) unless $LOAD_PATH.include?(path)
end

require "config"

Dir[File.join(PROJECT_ROOT, 'lib/tasks/**/*.rake')].each { |file| load file }

desc "Run all the tests"
task "test" => ["test:units", "test:integration"]

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
end

require "ci/reporter/rake/minitest" if ENV["RACK_ENV"] == "test"

task :default => :test

def logger
  Logging.logger.root
end

def search_config
  settings.search_config
end

def search_server
  search_config.search_server
end

def index_names
  case ENV["RUMMAGER_INDEX"]
  when "all"
    search_config.index_names
  when String
    [ENV["RUMMAGER_INDEX"]]
  else
    raise "You must specify an index name in RUMMAGER_INDEX, or 'all'"
  end
end
