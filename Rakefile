require "rake/testtask"
require "rest-client"
require "logging"

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

namespace :rummager do

  desc "Lists current Rummager indices, pass [all] to show inactive indices"
  task :list_indices, :all do |_, args|
    show_all = args[:all] || false
    all_index_names.each do |name|
      index_group = search_server.index_group(name)
      active_index_name = index_group.current.real_name
      if show_all
        index_names = index_group.index_names
      else
        index_names = [active_index_name]
      end
      puts "#{name}:"
      index_names.sort.each do |index_name|
        if index_name == active_index_name
          puts "* #{index_name}"
        else
          puts "  #{index_name}"
        end
      end
      puts
    end
  end

  desc "Migrates an index group to a new index"
  task :migrate_index do
    index_names.each do |index_name|
      index_group = search_server.index_group(index_name)

      new_index = index_group.create_index
      old_index = index_group.current

      if old_index.exists?
        new_index.populate_from old_index
        new_count = new_index.all_documents.size
        old_count = old_index.all_documents.size
        unless new_count == old_count
          logger.error(
            "Population miscount: new index has #{new_count} documents, " +
            "while old index has #{old_count}."
          )
          raise RuntimeError, "Population count mismatch"
        end
      end

      index_group.switch_to new_index
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
