require "rake/testtask"
require "rest-client"
require "logger"

File.join(File.dirname(__FILE__), "lib").tap do |path|
  $LOAD_PATH.unshift path unless $LOAD_PATH.include? path
end

require "search_config"

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
    @logger.add @level, message
  end
end

task :default => :test

def logger
  @logger ||= Logger.new(STDOUT).tap do |l|
    l.level = verbose ? Logger::DEBUG : Logger::INFO
  end
end

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

namespace :rummager do

  desc "Lists current Rummager indices"
  task :list_indices do
    all_index_names.each do |name|
      index = search_server.index(name)
      puts "#{name}: #{index.real_name || "(no index)"}"
    end
  end

  desc "Migrates an index group to a new index"
  task :migrate_index do
    index_names.each do |index_name|
      index_group = search_server.index_group(index_name)

      logger.info "Creating new #{index_name} index..."
      new_index = index_group.create_index
      logger.info "...index '#{new_index.real_name}' created"

      if index_group.current.exists?
        logger.info "Populating new #{index_name} index..."
        new_index.populate_from index_group.current
        logger.info "...index populated."
      end

      logger.info "Switching #{index_name}..."
      index_group.switch_to new_index
      logger.info "...switched"
    end
  end

  desc "Migrates from an index with the actual index name to an alias"
  task :migrate_from_unaliased_index do
    # WARNING: this is potentially dangerous, and will leave the search
    # unavailable for a very short (sub-second) period of time
    #
    # TODO: remove this task once it is no longer needed

    index_names.each do |index_name|
      index_group = search_server.index_group(index_name)

      real_index_name = index_group.current.real_name
      unless real_index_name == index_name
        # This task only makes sense if we're migrating from an unaliased index
        raise "Expecting index name #{index_name.inspect}; found #{real_index_name.inspect}"
      end

      logger.info "Creating new #{index_name} index..."
      new_index = index_group.create_index
      logger.info "...index '#{new_index.real_name}' created"

      logger.info "Populating new #{index_name} index..."
      new_index.populate_from index_group.current
      logger.info "...index populated."

      logger.info "Deleting #{index_name} index..."
      index_group.send :delete, CGI.escape(index_name)
      logger.info "...deleted."

      logger.info "Switching #{index_name}..."
      index_group.switch_to new_index
      logger.info "...switched"
    end
  end

  desc "Cleans out old indices"
  task :clean do
    index_names.each do |index_name|
      search_server.index_group(index_name).clean
    end
  end
end
