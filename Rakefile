require "rake/testtask"
require "rest-client"
require "logging"

PROJECT_ROOT = File.dirname(__FILE__)

File.join(PROJECT_ROOT, "lib").tap do |path|
  $LOAD_PATH.unshift path unless $LOAD_PATH.include? path
end

require "search_config"

Dir[File.join(PROJECT_ROOT, 'lib/tasks/*.rake')].each { |file| load file }

desc "Run all the tests"
task "test" => ["test:units", "test:functionals", "test:integration"]

namespace "test" do
  desc "Run the unit tests"
  Rake::TestTask.new("units") do |t|
    t.libs << "test"
    t.test_files = FileList["test/unit/**/*_test.rb"]
    t.verbose = true
  end

  desc "Run the functional tests"
  Rake::TestTask.new("functionals") do |t|
    t.libs << "test"
    t.test_files = FileList["test/functional/**/*_test.rb"]
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

class PushableLogger
  # Because RestClient uses the '<<' method, rather than the levelled Logger
  # methods, we have to put together a class that'll assign them a level

  def initialize(logger, level)
    @logger, @level = logger, level
  end

  def <<(message)
    @logger.send @level, message
  end
end

task :default => :test

logger = Logging.logger.root
logger.add_appenders Logging.appenders.stdout
logger.level = verbose ? :debug : :info

# Log all RestClient output at debug level, so it doesn't show up unless rake
# is invoked with the `--verbose` flag
RestClient.log = PushableLogger.new(Logging.logger[RestClient], :debug)

def search_config
  @search_config ||= SearchConfig.new
end

def search_server
  search_config.search_server
end

def index_names
  case ENV["RUMMAGER_INDEX"]
  when "all"
    all_index_names
  when String
    [ENV["RUMMAGER_INDEX"]]
  else
    raise "You must specify an index name in RUMMAGER_INDEX, or 'all'"
  end
end

def all_index_names
  search_config.index_names
end


